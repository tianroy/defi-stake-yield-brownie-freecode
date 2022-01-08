pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20 {
    constructor() public ERC20("fake use", "
    USDr") {
        _mint(msg.sender, 987654321e18);
    }

    function freeToken(address who) public {
        _mint(who, 888888e18);
    }
}
