// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

contract Ipool {
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

    function placeBid(uint256 newbid, uint256 premium) public {}

    function cancelBid() public {}

    function sellBid(uint256 seller_size) public {}

    function getBestBid(uint256 seller_size)
        public
        view
        returns (uint256 average_bid)
    {}

    function exercise() public {}

    function insertBid(uint256 newbid) internal {}

    function deposit() public payable {}

    function PoolBalance() public view returns (uint256) {}

    function userBalance() public view returns (uint256) {}

    function SecondToExpiry() public view returns (uint256) {}
}
