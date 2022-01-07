// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

// to do
// 1. sushi
// 2. transcation cost

// uncomment this below if need real ETH price !!!!!!!!
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract pool_plus {
    uint256 private constant NO_TRADE_CLOSE_TO_EXPIRE = 10; //seconds
    uint256 private constant MIN_BUYER_SIZE = 1e2;
    uint256 private constant MIN_SELLER_SIZE = 1e3;
    uint256 private constant MIN_DEPOSIT_SIZE = 5e2;
    uint256 private constant TRANSACTION_COST = 1; // so 1% for each trade or we use a formula

    // prevent two people draw liquidity at same time
    enum contract_status {
        open,
        locked
    }
    contract_status private STATUS = contract_status.open;

    //Pricefeed interfaces from chainlink
    // uncomment this below if need real ETH price !!!!!!!!
    // AggregatorV3Interface internal ethFeed;
    uint256 public ethPrice;

    address payable contract_address;

    // store cash balance for each user, not used in any option sub-pool
    mapping(address => uint256) public cash_balance;

    // bid_struct: each bid in bids (bids is the order book for each option)
    struct bid_struct {
        uint256 price; // usd per option
        uint256 size; // number of option x strike
        address user_id; //user address
    }
    // bids[id] is the order book for each option[id]
    mapping(uint256 => bid_struct[]) public bids;

    // user_struct saves all info for each user
    enum option_side {
        not_open,
        buyer,
        seller,
        exercised
    }
    struct user_struct {
        // size: for buyer is number of eth option x strike price he placed
        // size: for seller is number of eth option x strike price x (1+ yield) on expiry day
        uint256 size; //in USD,
        option_side side; //after expiry, re-allocate payoff depends on buyer or seller of option
        uint256 unusedpremium; //in USD, premium in the pool but not traded, for buyer only
    }
    // user[user_address][option-id] is each user
    mapping(address => mapping(uint256 => user_struct)) public user;

    // option_struct saves info for each option
    struct option_struct {
        uint256 strike; //Price in USD, for example 3300
        uint256 expiry; //Unix timestamp of expiration time, in second
        uint256 supply; //buyer place bid and seller can sell the bid; supply = number of option x strike
        uint256[] order; //order book sequence pointer, low bid to high bid, bids[id][order[0]] is the lowest bid
    }
    // op[id] is each option
    option_struct[] public op;

    // ********************
    // for testing purpose
    uint256 private id = 0; // for testing we only have one option
    uint256[] private order_for_test;
    bid_struct[] private order_book_for_one_option;
    // settlement_amount is only for testing purples, need to delete in production
    uint256 public settlement_amount;

    // ********************

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor() public {
        //ETH/USD Kovan feed
        // uncomment this below if need real ETH price !!!!!!!!
        // ethFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        contract_address = payable(address(this));

        // ********************
        // create fake option for testing
        option_struct memory option = option_struct({
            strike: 3300, // in USDC
            expiry: block.timestamp + 60, // 30seconds option, for testing purpose
            supply: 0, // after buyer place bid, supply will increase, in producation initial value =0
            order: order_for_test
        });
        op.push(option);
        // for testing purpose i give you fake money to play
        cash_balance[msg.sender] = 200000;
        // ********************
    }

    function placeBid(uint256 newbid, uint256 premium) public {
        // buyer place bid order but nothing traded yet
        // newbid in usd, eth option price
        address _user = msg.sender;
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            user[_user][id].side != option_side.seller,
            "seller of option cannot buy"
        );
        require(premium >= MIN_BUYER_SIZE, "Min size = 100");
        require(premium <= cash_balance[_user], "not enough cash"); //cash actually sell the balance first
        // update buyer
        // btw user.size only updated when seller sell the bid / only when trade
        user[_user][id].side = option_side.buyer;
        user[_user][id].unusedpremium += premium; //premium not used if seller not selling it
        cash_balance[_user] -= premium;

        // update option supply
        // below line convert the same unit as option seller, ie: number of eth option x strike price (not number of eth option x ethPrice)
        // 1x of dual contract needs: ethPrice/stirke size of option to hedge; size/strike > size/current spot!
        // Warnning below line: first multiply then divide to keep precision
        uint256 _size = (premium * op[id].strike) / newbid;
        op[id].supply += _size;

        // update order book
        bids[id].push(bid_struct(newbid, _size, _user));
        if (op[id].order.length == 0) {
            op[id].order.push(bids[id].length - 1);
        } else {
            insertBid(newbid);
        }
    }

    function cancelBid() public {
        // to make it easy, cancel all bids for testing stage
        // can make it cancel specific bid, but need more coding
        address payable _user = payable(msg.sender);
        require(
            STATUS == contract_status.open,
            "contract busy, try again later"
        );
        require(
            user[_user][id].side == option_side.buyer,
            "you need to buy option first"
        );
        require(
            user[_user][id].unusedpremium > 0,
            "your oder has been filled or cancelled"
        );
        STATUS = contract_status.locked;
        // update buyer
        //_user.transfer(user[_user][id].unusedpremium);
        cash_balance[_user] += user[_user][id].unusedpremium;
        user[_user][id].unusedpremium = 0;

        // update order book and option supply
        uint256[] memory old_order = op[id].order;
        uint256 k = 0;
        for (uint256 i = 0; i < old_order.length; i++) {
            if (bids[id][old_order[i]].user_id != _user) {
                // if this bid is not from this user
                op[id].order[k] = old_order[i];
                // k = how many bids we need to keep
                k++;
            } else {
                op[id].supply -= bids[id][old_order[i]].size;
            }
        }
        for (uint256 i = 0; i < old_order.length - k; i++) {
            op[id].order.pop();
        }
        STATUS = contract_status.open;
    }

    function sellBid(uint256 seller_size) public {
        // seller size is in usd, full notional / collateral collected
        // seller option == buyer dual conntract!
        address _user = msg.sender;
        require(op[id].order.length > 0, "cannot sell if there is no bid");
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            user[_user][id].side != option_side.buyer,
            "buyer of option cannot sell"
        );
        require(seller_size >= MIN_SELLER_SIZE, "Min size = 1000");
        require(seller_size <= op[id].supply, "low supply");
        require(seller_size <= cash_balance[_user], "not enough cash"); //cash actually sell the balance first
        cash_balance[_user] -= seller_size;

        // update order book
        uint256 remain = seller_size;
        uint256 sizexprice = 0;
        uint256 each_size;
        uint256 i = op[id].order.length - 1;
        // sell multiple bids to have enough size
        while (remain > 0) {
            each_size = bids[id][op[id].order[i]].size;
            if (remain >= each_size) {
                // update buyer
                user[bids[id][op[id].order[i]].user_id][id].size += each_size;
                user[bids[id][op[id].order[i]].user_id][id]
                    .unusedpremium -= ((each_size *
                    bids[id][op[id].order[i]].price) / op[id].strike);
                // update seller
                sizexprice += (each_size * bids[id][op[id].order[i]].price);
                // update option
                op[id].supply -= each_size;
                // update order book
                bids[id][op[id].order[i]].size = 0;
                // last one is the highest one, pop the highest bid
                op[id].order.pop();
                remain -= each_size;
            } else {
                // update buyer
                user[bids[id][op[id].order[i]].user_id][id].size += remain;
                user[bids[id][op[id].order[i]].user_id][id]
                    .unusedpremium -= ((remain *
                    bids[id][op[id].order[i]].price) / op[id].strike);
                // update seller
                sizexprice += (remain * bids[id][op[id].order[i]].price);
                // update option
                op[id].supply -= remain;
                // update order book
                bids[id][op[id].order[i]].size -= remain;
                remain = 0;
            }
            i--;
        }
        // update seller
        getEthPrice();
        //expiry = (sizexprice / seller_size / ethPrice + 1 )x seller_size
        user[_user][id].size += ((sizexprice + seller_size * ethPrice) /
            ethPrice);
        user[_user][id].side = option_side.seller;
    }

    function getBestBid(uint256 seller_size)
        public
        view
        returns (uint256 average_bid)
    {
        // same logic as sellOption Function but not updating options and users
        require(op[id].order.length > 0, "cannot sell if there is no bid");
        require(seller_size >= MIN_SELLER_SIZE, "min size = 1000");
        require(seller_size <= op[id].supply, "low supply");
        uint256 remain = seller_size;
        uint256 sizexprice = 0;
        uint256 each_bid_amount;
        uint256 i = op[id].order.length - 1;
        while (remain > 0) {
            each_bid_amount = bids[id][op[id].order[i]].size;
            if (remain >= each_bid_amount) {
                sizexprice += (each_bid_amount *
                    bids[id][op[id].order[i]].price);
                remain -= each_bid_amount;
            } else {
                sizexprice += (remain * bids[id][op[id].order[i]].price);
                remain = 0;
            }
            i--;
        }
        average_bid = sizexprice / seller_size;
        return average_bid;
    }

    function exercise() public {
        // for testing purpose please set a fake eth price
        address _user = msg.sender;
        option_side _side = user[_user][id].side;
        require(
            _side == option_side.seller || _side == option_side.buyer,
            "You have no position"
        );
        require(
            op[id].expiry <= block.timestamp,
            "Cannot exercise before expiry"
        );
        require(_side != option_side.exercised, "You already excercised ");
        uint256 _size = user[_user][id].size;
        uint256 _strike = op[id].strike;
        if (_side == option_side.buyer) {
            require(_size > 0, "No one sell your bid and nothing to expire");
            require(ethPrice < _strike, "Expire worth zero");
            if (user[_user][id].unusedpremium > 0) {
                cancelBid();
            }
        }
        if (_side == option_side.seller) {
            if (ethPrice < _strike) {
                // Be very careful!!!!!!!!!!!!
                // NEED to transfer/sushi USD into ETH here !!! below is ETH amount!!!
                //_user.transfer(_size / _strike);
                cash_balance[_user] += _size / _strike;
                // please delete below line later
                settlement_amount = _size / _strike;
            } else {
                //_user.transfer(_size);
                cash_balance[_user] += _size;
                // please delete below line later
                settlement_amount = _size;
            }
        } else {
            if (ethPrice < _strike) {
                // below is for cash settlement in usd
                // noted: when we record buyer size = usd_collected / %price * strike / ethPrice
                //_user.transfer((_size * (_strike - ethPrice)) / _strike);
                cash_balance[_user] += ((_size * (_strike - ethPrice)) /
                    _strike);
                // please delete below line later
                settlement_amount = (_size * (_strike - ethPrice)) / _strike;
            } // else do nothing: expire worth zero
        }
        user[_user][id].side = option_side.exercised;
    }

    function insertBid(uint256 newbid) internal {
        // insert the newbid in to bids according to the newbid level, lowest bid at 0 position
        uint256 left = 0;
        uint256 right = op[id].order.length - 1;
        uint256 mid;

        // binary tree insert
        while (left < right) {
            mid = (left + right) / 2;
            if (newbid > bids[id][op[id].order[mid]].price) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        // when loop ends:
        // if left > right mid is correct position to insert
        // if left == right, need to compare once more with right
        if (left == right) {
            if (newbid > bids[id][op[id].order[left]].price) {
                mid = left + 1;
            } else {
                mid = left;
            }
        }
        // first push the pointer of newbid /last one of bids into the order array
        op[id].order.push(bids[id].length - 1);
        if (mid < op[id].order.length - 1) {
            for (uint256 i = op[id].order.length - 1; i > mid; i--) {
                // copy the old value to the right next one
                op[id].order[i] = op[id].order[i - 1];
            }
            // insert the pointer(aka order) of newbid
            op[id].order[mid] = bids[id].length - 1;
        } // else if mid == order.lenghth, newbid is highest and already been pushed to the last one of order
    }

    //Returns the latest ETH price
    function getEthPrice() public {
        // uncomment this below if need real ETH price !!!!!!!!
        //(
        //    uint80 roundID,
        //    int256 price,
        //    uint startedAt,
        //    uint timeStamp,
        //    uint80 answeredInRound
        //) = ethFeed.latestRoundData();
        //// If the round is not complete yet, timestamp is 0
        //require(timeStamp > 0, "Round not complete");
        ////Price should never be negative thus cast int to unit is ok
        ////Price is 8 decimal places and will require 1e10 correction later to 18 places
        //ethPrice = uint256(price);
        ethPrice = 3799;
    }

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT_SIZE, "Min size = 500");
        cash_balance[msg.sender] += msg.value;
    }

    function PoolBalance() public view returns (uint256) {
        return (contract_address.balance);
    }

    function getOrder() public view returns (uint256[] memory) {
        return op[id].order;
    }

    function userBalance() public view returns (uint256) {
        return cash_balance[msg.sender];
    }

    function SecondToExpiry() public view returns (uint256) {
        return (op[id].expiry - block.timestamp);
    }

    function setFakeETH(uint256 _eth) public {
        ethPrice = _eth;
    }

    function createFakeBuyer() private {
        // for testing only, we create an option with some supply
        // only use before before placeBid, otherwise order will be wrong!!!
        address fake_user = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        order_book_for_one_option.push(bid_struct(330, 1650, fake_user));
        order_book_for_one_option.push(bid_struct(396, 1320, fake_user));
        order_book_for_one_option.push(bid_struct(132, 6600, fake_user));
        order_book_for_one_option.push(bid_struct(198, 16500, fake_user));
        bids[id] = order_book_for_one_option;
        user[fake_user][id].side = option_side.buyer;
        user[fake_user][id].unusedpremium += 709;
        op[id].supply += 26070;
        op[id].order = [2, 3, 0, 1];
        cash_balance[fake_user] = 100000;
    }
}
