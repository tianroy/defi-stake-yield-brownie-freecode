pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20 {
    constructor() public ERC20("Dapp Token", "DAPP") {
        _mint(msg.sender, 1000000000000000000000000);
    }

    function freeToken(address who) public {
        _mint(who, 1000000e18);
    }
}
