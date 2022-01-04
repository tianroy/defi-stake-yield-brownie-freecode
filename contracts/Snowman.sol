// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

contract Snowman {
    struct Option {
        uint256 id; // i.e. 1
        address sourceTokenAddress; //usdc
        address targetTokenAddress; //weth
        uint256 strike; // 3300 Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint256 expiry; // +30sec Unix timestamp of expiration time
        uint256 supply; //  no. of option x strike
        uint256[] order; // order book sequence pointer, low bid to high bid
    }

    function deposit(uint256 amount, address tokenAddress)
        external
        returns (bool)
    {
        // Require token is either WETH or USDC
    }

    function withdraw(uint256 amount, address tokenAddress)
        external
        returns (bool)
    {
        // Require token is either WETH or USDC
    }

    function getBalance(address tokenAddress) public returns (uint256) {
        // Require token is either WETH or USDC
    }

    // optionId = 1
    // price = 380usd (if current eth price = 3800, 380 means 10%)
    // if totalPremium = 1900 means you bought 5 x 380 option, ie: at expiry, you can sell 5 ETH at strike
    function buyOption(
        uint256 optionId,
        uint256 price,
        uint256 totalPremium
    ) public {}

    // if you sell 5x ETH option and ETH = 3800, then amount = 5x 3800 = 19000; aka: fully collateralized, full loss
    function sellOption(uint256 optionId, uint256 amount) public {}

    function exerciseOption(uint256 optionId) public returns (uint256) {
        return 1;
    }

    // appox supply, because ETH price is change every second
    function getOptionBalance(uint256 optionId) public returns (uint256) {
        return 1;
    }
}
