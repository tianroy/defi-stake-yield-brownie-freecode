// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// uncomment this below if need real ETH price !!!!!!!!
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract pool {
    
    uint256 constant public NO_TRADE_CLOSE_TO_EXPIRE = 10; //seconds
    uint256 constant public MIN_BUYER_SIZE = 1e3;
    uint256 constant public MIN_SELLER_SIZE = 1e3;

    // prevent two people draw liquidity at same time
    enum contract_status {open, locked}
    contract_status public STATUS = contract_status.open;

    // temp for testing purples, need to delete in production
    uint256 public settlement_amount;

    //Pricefeed interfaces from chainlink
    // uncomment this below if need real ETH price !!!!!!!!
    // AggregatorV3Interface internal ethFeed;
    uint256 public ethPrice;
    
    address payable contract_address;
    
    struct option_struct {
        uint256 strike; //Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint256 price_percent; //Fee in USD option worth
        uint256 expiry; //Unix timestamp of expiration time
        uint256 supply; //require options buyer stake premium, before the dual currency buyer, ie: option seller can sell it
    }
    enum option_side {not_open, buyer, seller, exercised}
    struct player_struct {
        uint256 amount; //in USD, number of eth option x strike price (different than number of option x ethPrice)
        option_side side; //after expiry, re-allocate payoff depends on buyer or seller of option
        uint256 premium; //in USD, premium spent 
    }
    //mapping: player[player_address][option_id] is a player_struct
    mapping(address => mapping(uint256 => player_struct)) public player;

    uint256 public option_id = 0; // for testing we only have one option
    option_struct[] public options;

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor() public {
        //ETH/USD Kovan feed
        // uncomment this below if need real ETH price !!!!!!!!
        // ethFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        contract_address = payable(address(this));
        option_struct memory option = option_struct(
            {
                strike: 3300,
                price_percent: 10, // for testing purpose we buy and sell at same price = 10%
                expiry: block.timestamp + 30, // 30seconds option, for testing purpose
                supply: 0 //after buyer place bid, supply will increase
            }
        );
        options.push(option);
    }
    
    //Returns the latest ETH price
    function getEthPrice() public  {
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


    function SellOption() public payable {
        // sell option = buy dual conntract!
        address _player = msg.sender;
        uint256 _amount = msg.value; //usd full notional / collateral collected
        require(options[option_id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE, "Already expired or too close to expiry");
        require(player[_player][option_id].side != option_side.buyer, "buyer of option cannot sell");
        require(_amount >= MIN_SELLER_SIZE, "Min size = 1000");
        require(_amount <= options[option_id].supply, "low supply");
        player[_player][option_id].side = option_side.seller;
        player[_player][option_id].amount += _amount;
        options[option_id].supply -= _amount;
    }

    function buyOption() public payable {
        address _player = msg.sender;
        uint256 _amount = msg.value; //usd premium collected 
        require(options[option_id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE, "Already expired or too close to expiry");
        require(player[_player][option_id].side != option_side.seller, "seller of option cannot buy");
        require(_amount >= MIN_BUYER_SIZE, "Min size = 1000");
        player[_player][option_id].side = option_side.buyer;
        getEthPrice();       // need to convert usd size for future use
        // buyer_notional = usd_premium / %_price
        // real notional: player_amount[_player][option_id] += _amount * 100 / options[option_id].price_percent;
        // below line convert the same unit as option seller, ie: number of eth option x strike price (not number of eth option x ethPrice)
        // 1x of dual contract needs: ethPrice/stirke size of option to hedge; amount/strike > amount/current spot!
        // Warnning below line: first multiply then divide to keep precision
        player[_player][option_id].premium += _amount;
        player[_player][option_id].amount += (_amount * 100 / options[option_id].price_percent * options[option_id].strike / ethPrice);
        options[option_id].supply += player[_player][option_id].amount;
    }

    function cancelBuyOption() public {
        address payable _player = msg.sender;
        require(STATUS == contract_status.open, "contract busy, try again later");
        require(player[_player][option_id].side == option_side.buyer, "need to buy option first");
        require(options[option_id].supply > 0, "your buy order has been all taken by the sellers");
        uint256 _amount; 
        STATUS = contract_status.locked;
        if (options[option_id].supply < player[_player][option_id].amount) { 
            _amount = options[option_id].supply;
        } else {
            _amount = player[_player][option_id].amount;
        }
        //_player.transfer(_amount / options[option_id].strike *);
        player[_player][option_id].amount -= _amount;
        options[option_id].supply -= _amount;
        STATUS = contract_status.open;
    }

    function exercise() public {
        // for testing purpose please set a fake eth price
        address payable _player = msg.sender;
        option_side _side = player[_player][option_id].side;
        uint256 _amount = player[_player][option_id].amount;
        uint256 _strike = options[option_id].strike;

        require(options[option_id].expiry <= block.timestamp, "Cannot exercise before expiry");
        require (_side != option_side.exercised, "You already excercised ");
        require (_side == option_side.seller || _side == option_side.buyer, "You have no position");
        require (!(_side == option_side.buyer && ethPrice >= _strike), "Expire worth zero");
        if (_side == option_side.seller) {
            if (ethPrice < _strike) {
                // Be very careful!!!!!!!!!!!!
                // NEED to transfer/sushi USD into ETH here !!! below is ETH amount!!!
                _player.transfer((options[option_id].price_percent + 100) * _amount / _strike / 100 );
                // please delete below line later
                settlement_amount = (options[option_id].price_percent + 100) * _amount / _strike / 100 ;
            } else {
                _player.transfer((options[option_id].price_percent + 100) * _amount / 100 );
                // please delete below line later
                settlement_amount = (options[option_id].price_percent + 100) * _amount / 100;
            }
        } else {
            cancelBuyOption();
            if (ethPrice < _strike) {
                // below is for cash settlement in usd
                // noted: when we record buyer amount = usd_collected / %price * strike / ethPrice
                _player.transfer( _amount * (_strike - ethPrice) / _strike);
                // please delete below line later
                settlement_amount = _amount * (_strike - ethPrice) / _strike;
            } // else do nothing: expire worth zero
        }
        player[_player][option_id].side = option_side.exercised;
    } 

    function PoolBalance() public view returns(uint256) {
        return(contract_address.balance);
    }
    
    function PlayerAmount() public view returns(uint256) {
        return(player[msg.sender][option_id].amount);
    }

    function PlayerSide() public view returns(option_side) {
        return(player[msg.sender][option_id].side);
    }

    function SecondToExpiry() public view returns(uint256) {
        return(options[option_id].expiry - block.timestamp);
    }

    function setFakeETH(uint256 _eth) public {
        ethPrice = _eth;
    }

}
