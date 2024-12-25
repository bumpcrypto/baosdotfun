// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IHoneyLocker {
    /// @notice Initializes the HoneyLocker contract
    /// @param _owner The address of the contract owner
    /// @param _honeyQueen The address of the HoneyQueen contract
    /// @param _referral The address for referral
    /// @param _unlocked Whether the contract should enforce restrictions
    function initialize(address _owner, address _honeyQueen, address _referral, bool _unlocked) external;
 
    /// @notice Executes a wildcard function call to an allowed target contract
    /// @param _contract The address of the target contract
    /// @param data The calldata for the function call
    function wildcard(address _contract, bytes calldata data) external;
 
    /// @notice Stakes LP tokens in a staking contract
    /// @param _LPToken The address of the LP token
    /// @param _stakingContract The address of the staking contract
    /// @param _amount The amount of LP tokens to stake
    /// @param data The calldata for the stake function
    function stake(address _LPToken, address _stakingContract, uint256 _amount, bytes memory data) external;
 
    /// @notice Unstakes LP tokens from a staking contract
    /// @param _LPToken The address of the LP token
    /// @param _stakingContract The address of the staking contract
    /// @param _amount The amount of LP tokens to unstake
    /// @param data The calldata for the unstake function
    function unstake(address _LPToken, address _stakingContract, uint256 _amount, bytes memory data) external;
 
    /// @notice Burns BGT tokens for BERA and withdraws BERA
    /// @param _amount The amount of BGT to burn
    function burnBGTForBERA(uint256 _amount) external;
 
    /// @notice Withdraws LP tokens after expiration
    /// @param _LPToken The address of the LP token
    /// @param _amount The amount of LP tokens to withdraw
    function withdrawLPToken(address _LPToken, uint256 _amount) external;
 
    /// @notice Migrates LP tokens to a new HoneyLocker
    /// @param _LPTokens An array of LP token addresses
    /// @param _amountsOrIds An array of amounts or IDs corresponding to the LP tokens
    /// @param _newHoneyLocker The address of the new HoneyLocker
    function migrate(address[] calldata _LPTokens, uint256[] calldata _amountsOrIds, address payable _newHoneyLocker) external;
 
    /// @notice Claims rewards from a staking contract
    /// @param _stakingContract The address of the staking contract
    /// @param data The calldata for the claim rewards function
    function claimRewards(address _stakingContract, bytes memory data) external;
 
    /// @notice Deposits and locks LP tokens
    /// @param _LPToken The address of the LP token
    /// @param _amountOrId The amount or ID of the LP token
    /// @param _expiration The expiration timestamp for the lock
    function depositAndLock(address _LPToken, uint256 _amountOrId, uint256 _expiration) external;
 
    /// @notice Delegates BGT tokens to a validator
    /// @param _amount The amount of BGT to delegate
    /// @param _validator The address of the validator
    function delegateBGT(uint128 _amount, address _validator) external;
 
    /// @notice Cancels a queued boost for BGT delegation
    /// @param _amount The amount of BGT to cancel
    /// @param _validator The address of the validator
    function cancelQueuedBoost(uint128 _amount, address _validator) external;
 
    /// @notice Drops a boost for BGT delegation
    /// @param _amount The amount of BGT to drop
    /// @param _validator The address of the validator
    function dropBoost(uint128 _amount, address _validator) external;
 
    /// @notice Withdraws BERA from the contract
    /// @param _amount The amount of BERA to withdraw
    function withdrawBERA(uint256 _amount) external;
 
    /// @notice Withdraws ERC20 tokens from the contract
    /// @param _token The address of the ERC20 token
    /// @param _amount The amount of tokens to withdraw
    function withdrawERC20(address _token, uint256 _amount) external;
 
    /// @notice Withdraws ERC721 tokens from the contract
    /// @param _token The address of the ERC721 token
    /// @param _id The ID of the token to withdraw
    function withdrawERC721(address _token, uint256 _id) external;
 
    /// @notice Withdraws ERC1155 tokens from the contract
    /// @param _token The address of the ERC1155 token
    /// @param _id The ID of the token to withdraw
    /// @param _amount The amount of tokens to withdraw
    /// @param data Additional data for the transfer
    function withdrawERC1155(address _token, uint256 _id, uint256 _amount, bytes calldata data) external;
 
    /// @notice Activates a boost for a validator
    /// @param _validator The address of the validator
    function activateBoost(address _validator) external;
}