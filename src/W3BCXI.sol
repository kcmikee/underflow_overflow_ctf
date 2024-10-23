// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @notice the goal of this ctf is to drain all the functd from this contract.
 */

contract W3BCXI {
    address owner;
    mapping(address => uint256) deposits;

    uint256 constant BASIS_POINTS = 1e4;
    uint256 public feeBps = 3141;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() payable {
        owner = msg.sender;
        deposits[owner] = type(uint256).max; // mark the original owner
    }

    function deposit(address receiver, uint256 donationBps) external payable {
        uint256 value;
        uint256 fee = _calculateFee(msg.value, donationBps);

        unchecked {
            value = msg.value - fee;
        }

        deposits[receiver] += value;
    }

    function withdraw() external {
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }

    function setFee(uint256 _feeBps) external onlyOwner {
        feeBps = _feeBps;
    }

    function rescueFunds() external {
        require(deposits[msg.sender] == type(uint256).max); // only original owner can rescue
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function viewDeposit(address account) external view returns (uint256) {
        return deposits[account];
    }

    function _calculateFee(
        uint256 amount,
        uint256 bonusBps
    ) internal view returns (uint256) {
        unchecked {
            return (amount * (feeBps + bonusBps)) / BASIS_POINTS;
        }
    }

    function drained() external view returns (bool) {
        return address(this).balance == 0;
    }

    receive() external payable {}

    fallback() external payable {}
}

contract W3bCXIFactory {
    W3BCXI public w3bCxi;
    address owner;

    mapping(address => bool) public whitelisted;
    mapping(address => mapping(address => bool)) public isRegisteredOwner;
    mapping(address => bool) public isRegisteredPlayer;
    mapping(address => string) public PlayerName;
    mapping(address => bool) public hasCompleted;

    string[] public Winners;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function whitelist(address[] memory wallets) external onlyOwner {
        for (uint i; i < wallets.length; i++) {
            whitelisted[wallets[i]] = true;
        }
    }

    function register(string memory name) external returns (address) {
        require(!isRegisteredPlayer[msg.sender], "I know you already!");
        isRegisteredPlayer[msg.sender] = true;
        require(whitelisted[msg.sender], "You are not whitelisted");
        w3bCxi = new W3BCXI();
        payable(address(w3bCxi)).transfer(0.001 ether);
        isRegisteredOwner[msg.sender][address(w3bCxi)] = true;
        PlayerName[msg.sender] = name;
        return address(w3bCxi);
    }

    function complete(address _w3bcxi) external returns (bool) {
        require(isRegisteredOwner[msg.sender][_w3bcxi], "Impersonator!!!");
        require(!hasCompleted[msg.sender], "What do you want again!!!");
        if (w3bCxi.drained()) {
            hasCompleted[msg.sender] = true;
            Winners.push(PlayerName[msg.sender]);
            return true;
        }
        return false;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(w3bCxi).balance}("");
        require(success);
    }

    function addFunds() external payable returns (bool) {
        return true;
    }
}
