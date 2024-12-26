// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PBAO Token
 * @notice This is the incentive token that gets locked in HoneyLocker when users contribute to BAO fundraising
 * @dev Only authorized BAO contracts can mint tokens, and only the admin (team multisig) can authorize BAO contracts
 */
contract PBAO is ERC20, Ownable {
    // Mapping of authorized BAO contracts that can mint pBAO
    mapping(address => bool) public authorizedMinters;

    // Events
    event MinterAuthorized(address indexed baoContract);
    event MinterRevoked(address indexed baoContract);
    event TokensMinted(address indexed baoContract, address indexed recipient, uint256 amount);

    constructor(address admin) ERC20("Locked BAO", "pBAO") Ownable(admin) {}

    /**
     * @notice Authorize a BAO contract to mint pBAO tokens
     * @param baoContract The address of the BAO contract to authorize
     */
    function authorizeMinter(address baoContract) external onlyOwner {
        require(baoContract != address(0), "Invalid BAO contract address");
        require(!authorizedMinters[baoContract], "Already authorized");
        
        authorizedMinters[baoContract] = true;
        emit MinterAuthorized(baoContract);
    }

    /**
     * @notice Revoke a BAO contract's authorization to mint pBAO tokens
     * @param baoContract The address of the BAO contract to revoke
     */
    function revokeMinter(address baoContract) external onlyOwner {
        require(authorizedMinters[baoContract], "Not authorized");
        
        authorizedMinters[baoContract] = false;
        emit MinterRevoked(baoContract);
    }

    /**
     * @notice Mint pBAO tokens to a recipient. Only callable by authorized BAO contracts
     * @param recipient The address to receive the tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        _mint(recipient, amount);
        emit TokensMinted(msg.sender, recipient, amount);
    }

    /**
     * @notice Check if a contract is authorized to mint pBAO tokens
     * @param baoContract The address to check
     * @return bool True if the contract is authorized to mint
     */
    function isMinterAuthorized(address baoContract) external view returns (bool) {
        return authorizedMinters[baoContract];
    }
} 