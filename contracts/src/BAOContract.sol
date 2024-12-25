// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager, IUniswapV3Factory, ILockerFactory, ILocker} from "./interface.sol";
import {IERC721Receiver} from "./LPLocker/IERC721Reciever.sol";
import {DaosWorldV1Token} from "./DaosWorldV1Token.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IHoneyLocker} from "./IHoneyLocker.sol";

contract BAOContract is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using TickMath for int24;

    uint24 public constant UNI_V3_FEE = 10000;
    uint256 public constant SUPPLY_TO_LP = 100_000_000 ether;
    IUniswapV3Factory public constant UNISWAP_V3_FACTORY = IUniswapV3Factory(0x33128a8fC17869897dcE68Ed026d694621f6FDfD);
    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1);
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    ILockerFactory public liquidityLockerFactory;
    address public liquidityLocker;
    IHoneyLocker public honeyLocker;

    // Tier-based lock periods (in days)
    mapping(uint256 => uint256) public tierLockPeriods;
    // Track LP positions and their lock data
    mapping(uint256 => address) public lpPositionOwner;
    mapping(uint256 => uint256) public lpPositionTier;
    mapping(uint256 => uint256) public lpPositionLockExpiry;

    event LPPositionLocked(uint256 indexed tokenId, address indexed owner, uint256 tier, uint256 lockExpiry);

    uint256 public totalRaised;
    uint256 public fundraisingGoal;
    bool public fundraisingFinalized;
    bool public goalReached;
    uint256 public fundraisingDeadline;
    uint256 public fundExpiry;
    uint256 public constant SUPPLY_TO_FUNDRAISERS = 1_000_000_000 * 1e18;
    uint8 public lpFeesCut = 60;
    address public protocolAdmin;
    string public name;
    string public symbol;
    address public baoToken;

    // If maxWhitelistAmount > 0, then its whitelist only. And this is the max amount you can contribute.
    uint256 public maxWhitelistAmount;
    // If maxPublicContributionAmount > 0, then you cannot contribute more than this in public rounds.
    uint256 public maxPublicContributionAmount;

    // The amount of ETH you've contributed
    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;
    address[] public whitelistArray;
    address[] public contributors;

    event Contribution(address indexed contributor, uint256 amount);
    event FundraisingFinalized(bool success);
    event Refund(address indexed contributor, uint256 amount);
    event AddWhitelist(address);
    event RemoveWhitelist(address);

    // Events for new functionality
    event LPUnstaked(uint256 indexed tokenId, address indexed owner);
    event RewardsClaimed(address indexed user, uint256 amount);
    event TokensBurned(address indexed user, uint256 baoAmount, uint256 beraAmount);

    // Event for BAO delegation
    event BAODelegated(address indexed user, uint128 amount, address indexed validator);

    constructor(
        uint256 _fundraisingGoal,
        string memory _name,
        string memory _symbol,
        uint256 _fundraisingDeadline,
        uint256 _fundExpiry,
        address _daoManager,
        address _liquidityLockerFactory,
        uint256 _maxWhitelistAmount,
        address _protocolAdmin,
        uint256 _maxPublicContributionAmount,
        address _honeyLocker
    ) Ownable(_daoManager) {
        require(_fundraisingGoal > 0, "Fundraising goal must be greater than 0");
        require(_fundraisingDeadline > block.timestamp, "_fundraisingDeadline > block.timestamp");
        require(_fundExpiry > fundraisingDeadline, "_fundExpiry > fundraisingDeadline");
        name = _name;
        symbol = _symbol;
        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        liquidityLockerFactory = ILockerFactory(_liquidityLockerFactory);
        maxWhitelistAmount = _maxWhitelistAmount;
        protocolAdmin = _protocolAdmin;
        maxPublicContributionAmount = _maxPublicContributionAmount;
        honeyLocker = IHoneyLocker(_honeyLocker);

        // Set default lock periods for each tier (in days)
        tierLockPeriods[1] = 1 days;  // Tier 1: 1 day
        tierLockPeriods[2] = 2 days;  // Tier 2: 2 days
        tierLockPeriods[3] = 3 days;  // Tier 3: 3 days
        tierLockPeriods[4] = 4 days;  // Tier 4: 4 days
        tierLockPeriods[5] = 5 days;  // Tier 5: 5 days
    }

    function contribute() public payable nonReentrant {
        require(!goalReached, "Goal already reached");
        require(block.timestamp < fundraisingDeadline, "Deadline hit");
        require(msg.value > 0, "Contribution must be greater than 0");
        if (maxWhitelistAmount > 0) {
            require(whitelist[msg.sender], "You are not whitelisted");
            require(contributions[msg.sender] + msg.value <= maxWhitelistAmount, "Exceeding maxWhitelistAmount");
        } else if (maxPublicContributionAmount > 0) {
            require(
                contributions[msg.sender] + msg.value <= maxPublicContributionAmount,
                "Exceeding maxPublicContributionAmount"
            );
        }

        uint256 effectiveContribution = msg.value;
        if (totalRaised + msg.value > fundraisingGoal) {
            effectiveContribution = fundraisingGoal - totalRaised;
            payable(msg.sender).transfer(msg.value - effectiveContribution);
        }

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        contributions[msg.sender] += effectiveContribution;
        totalRaised += effectiveContribution;

        emit Contribution(msg.sender, effectiveContribution);

        if (totalRaised == fundraisingGoal) {
            goalReached = true;
        }
    }

    function addToWhitelist(address[] calldata addresses) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!whitelist[addresses[i]]) {
                whitelist[addresses[i]] = true;
                whitelistArray.push(addresses[i]);
                emit AddWhitelist(addresses[i]);
            }
        }
    }

    function getWhitelistLength() public view returns (uint256) {
        return whitelistArray.length;
    }

    function removeFromWhitelist(address removedAddress) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        whitelist[removedAddress] = false;

        for (uint256 i = 0; i < whitelistArray.length; i++) {
            if (whitelistArray[i] == removedAddress) {
                whitelistArray[i] = whitelistArray[whitelistArray.length - 1];
                whitelistArray.pop();
                break;
            }
        }

        emit RemoveWhitelist(removedAddress);
    }

    function setMaxWhitelistAmount(uint256 _maxWhitelistAmount) public {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        maxWhitelistAmount = _maxWhitelistAmount;
    }

    function setMaxPublicContributionAmount(uint256 _maxPublicContributionAmount) public {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        maxPublicContributionAmount = _maxPublicContributionAmount;
    }

    // Function to set tier lock periods
    function setTierLockPeriod(uint256 tier, uint256 lockPeriod) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        require(tier > 0 && tier <= 5, "Invalid tier");
        require(lockPeriod > 0, "Lock period must be > 0");
        tierLockPeriods[tier] = lockPeriod;
    }

    // Modified finalizeFundraising to handle single-sided LP
    function finalizeFundraising(
        int24 initialTick, 
        int24 upperTick, 
        bytes32 salt,
        uint256[] memory contributorTiers
    ) external onlyOwner {
        require(goalReached, "Fundraising goal not reached");
        require(!fundraisingFinalized, "BAO tokens already minted");
        require(contributors.length == contributorTiers.length, "Arrays length mismatch");

        DaosWorldV1Token token = new DaosWorldV1Token{salt: salt}(name, symbol);
        baoToken = address(token);
        require(address(token) < WETH, "Invalid salt");

        // Mint tokens to contributors
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) / totalRaised;
            token.mint(contributor, tokensToMint);
        }

        emit FundraisingFinalized(true);
        fundraisingFinalized = true;

        // Setup Uniswap V3 pool with single-sided liquidity
        uint160 sqrtPriceX96 = initialTick.getSqrtRatioAtTick();
        address pool = UNISWAP_V3_FACTORY.createPool(address(token), WETH, UNI_V3_FEE);
        IUniswapV3Factory(pool).initialize(sqrtPriceX96);

        // Create single-sided LP position for each contributor
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 lpAmount = (contribution * SUPPLY_TO_LP) / totalRaised;

            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams(
                address(token),
                WETH,
                UNI_V3_FEE,
                initialTick,
                upperTick,
                lpAmount,
                0,  // No ETH/BERA provided
                0,  // Min token amount (not needed for single-sided)
                0,  // Min ETH/BERA amount (not needed for single-sided)
                address(this),
                block.timestamp
            );

            token.mint(address(this), lpAmount);
            token.approve(address(POSITION_MANAGER), lpAmount);
            
            // Mint single-sided LP position
            (uint256 tokenId,,,) = POSITION_MANAGER.mint(params);

            // Store LP position data
            lpPositionOwner[tokenId] = contributor;
            lpPositionTier[tokenId] = contributorTiers[i];
            uint256 lockExpiry = block.timestamp + tierLockPeriods[contributorTiers[i]];
            lpPositionLockExpiry[tokenId] = lockExpiry;

            // Lock in HoneyLocker
            POSITION_MANAGER.approve(address(honeyLocker), tokenId);
            honeyLocker.depositAndLock(address(POSITION_MANAGER), tokenId, lockExpiry);

            emit LPPositionLocked(tokenId, contributor, contributorTiers[i], lockExpiry);
        }

        // Transfer ownership to 0 address so no more tokens can be minted
        token.renounceOwnership();
    }

    // Allow contributors to get a refund if the goal is not reached
    function refund() external nonReentrant {
        require(!goalReached, "Fundraising goal was reached");
        require(block.timestamp > fundraisingDeadline, "Deadline not reached yet");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit Refund(msg.sender, contributedAmount);
    }

    // This function is for the DAO manager to trade
    function execute(address[] calldata contracts, bytes[] calldata data, uint256[] calldata msgValues)
        external
        onlyOwner
    {
        require(fundraisingFinalized);
        require(contracts.length == data.length && data.length == msgValues.length, "Array lengths mismatch");

        for (uint256 i = 0; i < contracts.length; i++) {
            (bool success,) = contracts[i].call{value: msgValues[i]}(data[i]);
            require(success, "Call failed");
        }
    }

    function extendFundExpiry(uint256 newFundExpiry) external onlyOwner {
        require(newFundExpiry > fundExpiry, "Must choose later fund expiry");
        fundExpiry = newFundExpiry;
        ILocker(liquidityLocker).extendFundExpiry(newFundExpiry);
    }

    function extendFundraisingDeadline(uint256 newFundraisingDeadline) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        require(!goalReached, "Fundraising goal was reached");
        require(newFundraisingDeadline > fundraisingDeadline, "new fundraising deadline must be > old one");
        fundraisingDeadline = newFundraisingDeadline;
    }

    function emergencyEscape() external {
        require(msg.sender == protocolAdmin, "must be protocol admin");
        require(!fundraisingFinalized, "fundraising already finalized");
        (bool success,) = protocolAdmin.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Fallback function to make contributions simply by sending ETH to the contract
    receive() external payable {
        if (!goalReached && block.timestamp < fundraisingDeadline) {
            contribute();
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Function to unstake LP position after lock period
    function unstakeLP(uint256 tokenId) external nonReentrant {
        require(lpPositionOwner[tokenId] == msg.sender, "Not the LP position owner");
        require(block.timestamp >= lpPositionLockExpiry[tokenId], "Lock period not expired");

        // Withdraw from HoneyLocker
        honeyLocker.withdraw(address(POSITION_MANAGER), tokenId);
        
        // Transfer LP token to owner
        POSITION_MANAGER.safeTransferFrom(address(this), msg.sender, tokenId);
        
        // Clear position data
        delete lpPositionOwner[tokenId];
        delete lpPositionTier[tokenId];
        delete lpPositionLockExpiry[tokenId];

        emit LPUnstaked(tokenId, msg.sender);
    }

    // Function to claim rewards from HoneyLocker
    function claimRewards(uint256 tokenId) external nonReentrant {
        require(lpPositionOwner[tokenId] == msg.sender, "Not the LP position owner");
        
        // Get pending rewards
        uint256 rewards = honeyLocker.getPendingRewards(tokenId);
        require(rewards > 0, "No rewards to claim");

        // Claim rewards from HoneyLocker
        honeyLocker.claimRewards(tokenId);
        
        // Transfer rewards to user
        (bool success,) = payable(msg.sender).call{value: rewards}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    // Function to burn BAO tokens for BERA
    function burnForBERA(uint256 baoAmount) external nonReentrant {
        require(baoAmount > 0, "Amount must be greater than 0");
        
        // Get BAO token contract
        DaosWorldV1Token token = DaosWorldV1Token(baoToken);
        require(token.balanceOf(msg.sender) >= baoAmount, "Insufficient BAO balance");

        // Calculate BERA amount based on current pool price
        uint256 beraAmount = calculateBERAAmount(baoAmount);
        require(address(this).balance >= beraAmount, "Insufficient BERA in contract");

        // Burn BAO tokens
        token.burnFrom(msg.sender, baoAmount);

        // Transfer BERA to user
        (bool success,) = payable(msg.sender).call{value: beraAmount}("");
        require(success, "BERA transfer failed");

        emit TokensBurned(msg.sender, baoAmount, beraAmount);
    }

    // Helper function to calculate BERA amount for burning BAO
    function calculateBERAAmount(uint256 baoAmount) public view returns (uint256) {
        // Get current pool price from Uniswap
        address pool = UNISWAP_V3_FACTORY.getPool(baoToken, WETH, UNI_V3_FEE);
        require(pool != address(0), "Pool does not exist");

        // Calculate based on pool reserves and price
        // This is a simplified calculation - you may want to use TWAP or other price oracle
        uint256 beraAmount = (baoAmount * getPoolPrice(pool)) / 1e18;
        return beraAmount;
    }

    // Helper function to get pool price
    function getPoolPrice(address pool) internal view returns (uint256) {
        // Implement price calculation based on pool reserves
        // This is a placeholder - implement actual price calculation logic
        return 1e18; // 1:1 price for example
    }

    // Function to delegate BAO tokens to a validator through HoneyLocker
    function delegateBAO(uint128 amount, address validator) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(validator != address(0), "Invalid validator address");
        
        // Get BAO token contract
        DaosWorldV1Token token = DaosWorldV1Token(baoToken);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient BAO balance");

        // Transfer BAO tokens from user to HoneyLocker
        token.transferFrom(msg.sender, address(honeyLocker), amount);
        
        // Delegate tokens to validator through HoneyLocker
        honeyLocker.delegateBGT(amount, validator);

        emit BAODelegated(msg.sender, amount, validator);
    }
}