// SPDX-License-Identifier: MIT
pragma solidity >0.6.7;

// uncomment this below if need real ETH price !!!!!!!!
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract pool {
    uint256 private constant NO_TRADE_CLOSE_TO_EXPIRE = 10; //seconds
    uint256 private constant MIN_BUYER_SIZE = 1e3;
    uint256 private constant MIN_SELLER_SIZE = 1e3;

    // prevent two people draw liquidity at same time
    enum contract_status {
        open,
        locked
    }
    contract_status public STATUS = contract_status.open;

    // temp for testing purples, need to delete in production
    uint256 public settlement_amount;

    //Pricefeed interfaces from chainlink
    // uncomment this below if need real ETH price !!!!!!!!
    // AggregatorV3Interface internal ethFeed;
    uint256 public ethPrice;

    address payable contract_address;

    // order book for different bids for same options
    struct bid_struct {
        uint256 price;
        uint256 amount;
        address player_address;
    }
    // for testing only, we create an option with some supply
    address constant fake_bid_address =
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256[] public order = [2, 3, 0, 1];
    bid_struct[] public bid;
    //mapping: bids[id] is a bid_struct
    mapping(uint256 => bid_struct[]) public bids;
    struct option_struct {
        uint256 strike; //Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint256 wrong_price; //Fee in USD option worth
        uint256 expiry; //Unix timestamp of expiration time
        uint256 supply; //require options buyer stake premium, before the dual currency buyer, ie: option seller can sell it
        uint256[] order; //order book sequence pointer, low bid to high bid
    }
    enum option_side {
        not_open,
        buyer,
        seller,
        exercised
    }
    struct player_struct {
        uint256 amount; //in USD, number of eth option x strike price (different than number of option x ethPrice)
        option_side side; //after expiry, re-allocate payoff depends on buyer or seller of option
        uint256 unused_premium; //in USD, premium in the pool but not traded, for buyer only
        uint256 sizexprice; //in USD x %Price, for seller only, accumulated notional x price traded
    }
    //mapping: player[player_address][id] is a player_struct
    mapping(address => mapping(uint256 => player_struct)) public player;

    uint256 public id = 0; // for testing we only have one option
    option_struct[] public op;

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor() public {
        //ETH/USD Kovan feed
        // uncomment this below if need real ETH price !!!!!!!!
        // ethFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        contract_address = payable(address(this));

        option_struct memory option = option_struct({
            strike: 3300,
            wrong_price: 10, // for testing purpose we buy and sell at same price = 10%
            expiry: block.timestamp + 30, // 30seconds option, for testing purpose
            supply: 10000, //after buyer place bid, supply will increase
            order: order
        });
        op.push(option);
        bid.push(bid_struct(10, 2000, fake_bid_address));
        bid.push(bid_struct(12, 1000, fake_bid_address));
        bid.push(bid_struct(6, 3000, fake_bid_address));
        bid.push(bid_struct(4, 2000, fake_bid_address));
        bids[id] = bid;
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

    function sellOption() public payable {
        // sell option == buy dual conntract!
        address _player = msg.sender;
        uint256 ask_size = msg.value; //usd full notional / collateral collected
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            player[_player][id].side != option_side.buyer,
            "buyer of option cannot sell"
        );
        require(ask_size >= MIN_SELLER_SIZE, "Min size = 1000");
        require(ask_size <= op[id].supply, "low supply");

        // update order book
        op[id].supply -= ask_size;
        uint256 _size = ask_size;
        uint256 _sizexprice = 0;
        uint256 each_bid_amount;
        uint256 i = op[id].order.length - 1;
        // sell multiple bids to have enough size
        while (_size > 0) {
            each_bid_amount = bids[id][op[id].order[i]].amount;
            if (_size >= each_bid_amount) {
                _sizexprice += (each_bid_amount *
                    bids[id][op[id].order[i]].price);
                _size -= each_bid_amount;
                op[id].supply -= each_bid_amount;
                bids[id][op[id].order[i]].amount = 0;
                // last one is the highest one, pop the highest bid
                op[id].order.pop();
            } else {
                _sizexprice += (_size * bids[id][op[id].order[i]].price);
                bids[id][op[id].order[i]].amount -= _size;
                op[id].supply -= _size;
                _size = 0;
            }
            i--;
        }
        // update seller
        player[_player][id].side = option_side.seller;
        player[_player][id].amount += ask_size;
        player[_player][id].sizexprice += _sizexprice;
        // here we need to update player[buyer]
        // premium unused and option filled
        // known issue here
    }

    function bestBid(uint256 _size) public view returns (uint256 average_bid) {
        // same logic as sellOption Function but not updating options and players
        require(_size >= MIN_SELLER_SIZE, "Min size = 1000");
        require(_size <= op[id].supply, "low supply");
        uint256 _sizexprice = 0;
        uint256 each_bid_amount;
        uint256 i = op[id].order.length - 1;
        while (_size > 0) {
            each_bid_amount = bids[id][op[id].order[i]].amount;
            if (_size >= each_bid_amount) {
                _sizexprice += (each_bid_amount *
                    bids[id][op[id].order[i]].price);
                _size -= each_bid_amount;
            } else {
                _sizexprice += (_size * bids[id][op[id].order[i]].price);
                _size = 0;
            }
            i--;
        }
        average_bid = _sizexprice / _size;
        return average_bid;
    }

    function buyOption(uint256 _newbid) public payable {
        address _player = msg.sender;
        uint256 _premium = msg.value; //usd premium collected
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            player[_player][id].side != option_side.seller,
            "seller of option cannot buy"
        );
        require(_premium >= MIN_BUYER_SIZE, "Min size = 1000");

        // update buyer
        player[_player][id].side = option_side.buyer;
        player[_player][id].unused_premium += _premium; //premium not yet filled by selling
        getEthPrice(); // need to convert usd size for future use
        // buyer_notional = usd_premium / %_price
        // real notional: player_amount[_player][id] += _amount * 100 / op[id].price;
        // below line convert the same unit as option seller, ie: number of eth option x strike price (not number of eth option x ethPrice)
        // 1x of dual contract needs: ethPrice/stirke size of option to hedge; amount/strike > amount/current spot!
        // Warnning below line: first multiply then divide to keep precision
        uint256 strike_notional = (((_premium * 100) / _newbid) *
            op[id].strike) / ethPrice;
        op[id].supply += strike_notional;
        // update order book
        placeBid(_newbid);
        bids[id].push(bid_struct(_newbid, strike_notional, _player));
        // btw player.amount only updated when seller sell the bid
    }

    function cancelBuyOption() public {
        address payable _player = payable(msg.sender);
        require(
            STATUS == contract_status.open,
            "contract busy, try again later"
        );
        require(
            player[_player][id].side == option_side.buyer,
            "need to buy option first"
        );
        require(
            op[id].supply > 0,
            "your buy order has been all taken by the sellers"
        );
        uint256 _amount;
        STATUS = contract_status.locked;
        if (op[id].supply < player[_player][id].amount) {
            _amount = op[id].supply;
        } else {
            _amount = player[_player][id].amount;
        }
        //_player.transfer(_amount / op[id].strike *);
        player[_player][id].amount -= _amount;
        op[id].supply -= _amount;
        STATUS = contract_status.open;
    }

    function exercise() public {
        // for testing purpose please set a fake eth price
        address payable _player = payable(msg.sender);
        option_side _side = player[_player][id].side;
        uint256 _amount = player[_player][id].amount;
        uint256 _strike = op[id].strike;

        require(
            op[id].expiry <= block.timestamp,
            "Cannot exercise before expiry"
        );
        require(_side != option_side.exercised, "You already excercised ");
        require(
            _side == option_side.seller || _side == option_side.buyer,
            "You have no position"
        );
        require(
            !(_side == option_side.buyer && ethPrice >= _strike),
            "Expire worth zero"
        );
        if (_side == option_side.seller) {
            if (ethPrice < _strike) {
                // Be very careful!!!!!!!!!!!!
                // NEED to transfer/sushi USD into ETH here !!! below is ETH amount!!!
                _player.transfer(
                    ((op[id].wrong_price + 100) * _amount) / _strike / 100
                );
                // please delete below line later
                settlement_amount =
                    ((op[id].wrong_price + 100) * _amount) /
                    _strike /
                    100;
            } else {
                _player.transfer(((op[id].wrong_price + 100) * _amount) / 100);
                // please delete below line later
                settlement_amount =
                    ((op[id].wrong_price + 100) * _amount) /
                    100;
            }
        } else {
            cancelBuyOption();
            if (ethPrice < _strike) {
                // below is for cash settlement in usd
                // noted: when we record buyer amount = usd_collected / %price * strike / ethPrice
                _player.transfer((_amount * (_strike - ethPrice)) / _strike);
                // please delete below line later
                settlement_amount = (_amount * (_strike - ethPrice)) / _strike;
            } // else do nothing: expire worth zero
        }
        player[_player][id].side = option_side.exercised;
    }

    function placeBid(uint256 newbid) public {
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
        // push the pointer of newbid /last one of bids into the order array
        op[id].order.push(op[id].order.length); //bid length is increasing 1 here
        if (mid < op[id].order.length - 1) {
            for (uint256 i = op[id].order.length - 1; i > mid; i--) {
                op[id].order[i] = op[id].order[i - 1];
            }
            op[id].order[mid] = op[id].order.length - 1; // bid length has increased 1 earlier
        } // else if mid == order.lenghth, newbid is highest and already been pushed to the last one of order
    }

    function PoolBalance() public view returns (uint256) {
        return (contract_address.balance);
    }

    function PlayerAmount() public view returns (uint256) {
        return (player[msg.sender][id].amount);
    }

    function PlayerSide() public view returns (option_side) {
        return (player[msg.sender][id].side);
    }

    function SecondToExpiry() public view returns (uint256) {
        return (op[id].expiry - block.timestamp);
    }

    function setFakeETH(uint256 _eth) public {
        ethPrice = _eth;
    }
}
