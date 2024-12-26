// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager} from "./interfaces/interface.sol";
import {IUniswapV3Factory} from "./interfaces/interface.sol";
import {IHoneyLocker} from "./interfaces/IHoneyLocker.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {BAOSDOTFUNV1TOKEN} from "./BAOSDOTFUNV1TOKEN.sol";
import {PBAO} from "./PBAO.sol";

/* 
This smart contract is the main entry point for the BAO contract. It is responsible for managing the fundraising process, 
creating the BAO token, and locking the LP tokens and pBAO tokens in HoneyLockers for whitelisted contributors to 
earn rewards.

This smart contract is heavily inspired by the DAOSDOTWORLD contracts on Base created by its founder @azflin on Twitter.  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
*/

contract BAO is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using TickMath for int24;

    // Constants
    uint24 public constant KODIAK_FEE = 10000; // 1%
    uint256 public constant SUPPLY_TO_LP = 100_000_000 ether;
    uint256 public constant SUPPLY_TO_FUNDRAISERS = 1_000_000_000 * 1e18;
    uint8 public lpFeesCut = 80; // 20% of these fees go to bribing validators for BGT to incentivize whitelisted contributors to continue staking their LP tokens
    uint256 public constant WEEK = 7 days;

    // Immutables
    IUniswapV3Factory public immutable KODIAK_FACTORY;
    INonfungiblePositionManager public immutable POSITION_MANAGER;
    address public immutable WETH;
    IHoneyLocker public immutable lpLocker;    // HoneyLocker for LP tokens
    IHoneyLocker public immutable pBAOLocker;  // HoneyLocker for pBAO tokens
    PBAO public immutable pBAO;                // pBAO token contract

    // State variables
    uint256 public totalRaised;
    uint256 public fundraisingGoal;
    bool public fundraisingFinalized;
    bool public goalReached;
    uint256 public fundraisingDeadline;
    uint256 public fundExpiry;
    string public name;
    string public symbol;
    address public baoToken;
    address public protocolAdmin;

    // Track LP token ID to pBAO amount mapping
    mapping(uint256 => uint256) public lpToPBAOAmount;  // tokenId => pBAO amount

    // Tier lock periods (in seconds)
    mapping(uint256 => uint256) public tierLockPeriods;

    // Whitelist settings
    uint256 public maxWhitelistAmount;
    uint256 public maxPublicContributionAmount;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;
    address[] public whitelistArray;
    address[] public contributors;

    // Events
    event Contribution(address indexed contributor, uint256 amount);
    event FundraisingFinalized(bool success);
    event Refund(address indexed contributor, uint256 amount);
    event AddWhitelist(address);
    event RemoveWhitelist(address);
    event LPPositionLocked(uint256 indexed tokenId, address indexed owner, uint256 tier, uint256 lockExpiry);
    event PBAOLocked(address indexed owner, uint256 amount, uint256 lockExpiry);
    event TokensUnstaked(uint256 indexed tokenId, address indexed owner, uint256 pBAOAmount);

    constructor(
        uint256 _fundraisingGoal,
        string memory _name,
        string memory _symbol,
        uint256 _fundraisingDeadline,
        uint256 _fundExpiry,
        address _daoManager,
        address _kodiakFactory,
        address _positionManager,
        address _weth,
        address _lpLocker,
        address _pBAOLocker,
        address _pBAO,
        uint256 _maxWhitelistAmount,
        address _protocolAdmin,
        uint256 _maxPublicContributionAmount
    ) Ownable(_daoManager) {
        require(_fundraisingGoal > 0, "Fundraising goal must be greater than 0");
        require(_fundraisingDeadline > block.timestamp, "_fundraisingDeadline > block.timestamp");
        require(_fundExpiry > _fundraisingDeadline, "_fundExpiry > fundraisingDeadline");

        name = _name;
        symbol = _symbol;
        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        maxWhitelistAmount = _maxWhitelistAmount;
        protocolAdmin = _protocolAdmin;
        maxPublicContributionAmount = _maxPublicContributionAmount;

        KODIAK_FACTORY = IUniswapV3Factory(_kodiakFactory);
        POSITION_MANAGER = INonfungiblePositionManager(_positionManager);
        WETH = _weth;
        lpLocker = IHoneyLocker(_lpLocker);
        pBAOLocker = IHoneyLocker(_pBAOLocker);
        pBAO = PBAO(_pBAO);

        // Set linear lock periods over a week
        // Tier 5: 1.4 days
        // Tier 4: 2.8 days
        // Tier 3: 4.2 days
        // Tier 2: 5.6 days
        // Tier 1: 7 days
        tierLockPeriods[5] = (WEEK * 1) / 5;  // 1.4 days
        tierLockPeriods[4] = (WEEK * 2) / 5;  // 2.8 days
        tierLockPeriods[3] = (WEEK * 3) / 5;  // 4.2 days
        tierLockPeriods[2] = (WEEK * 4) / 5;  // 5.6 days
        tierLockPeriods[1] = WEEK;            // 7 days
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

    function finalizeFundraising(
        int24 initialTick,
        int24 upperTick,
        bytes32 salt,
        uint256[] memory contributorTiers
    ) external onlyOwner {
        require(goalReached, "Fundraising goal not reached");
        require(!fundraisingFinalized, "BAO tokens already minted");
        require(contributors.length == contributorTiers.length, "Arrays length mismatch");

        // 1. Create BAO token
        BAOSDOTFUNV1TOKEN token = new BAOSDOTFUNV1TOKEN{salt: salt}(name, symbol);
        baoToken = address(token);
        require(address(token) < WETH, "Invalid salt");

        // 2. Mint tokens to contributors
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) / totalRaised;
            token.mint(contributor, tokensToMint);

            // Mint pBAO tokens proportional to contribution
            uint256 pBAOToMint = (contribution * SUPPLY_TO_LP) / totalRaised;
            pBAO.mint(address(this), pBAOToMint);

            // Lock pBAO tokens in pBAOLocker
            uint256 lockExpiry = block.timestamp + tierLockPeriods[contributorTiers[i]];
            ERC20(address(pBAO)).approve(address(pBAOLocker), pBAOToMint);
            pBAOLocker.depositAndLock(address(pBAO), pBAOToMint, lockExpiry);
            
            emit PBAOLocked(contributor, pBAOToMint, lockExpiry);
        }

        // 3. Setup Kodiak pool with single-sided liquidity
        uint160 sqrtPriceX96 = initialTick.getSqrtRatioAtTick();
        address pool = KODIAK_FACTORY.createPool(address(token), WETH, KODIAK_FEE);
        IUniswapV3Factory(pool).initialize(sqrtPriceX96);

        // 4. Create and lock LP positions for each contributor
        token.mint(address(this), SUPPLY_TO_LP);
        token.approve(address(POSITION_MANAGER), SUPPLY_TO_LP);

        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 lpAmount = (contribution * SUPPLY_TO_LP) / totalRaised;

            // Create LP position
            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: address(token),
                token1: WETH,
                fee: KODIAK_FEE,
                tickLower: initialTick,
                tickUpper: upperTick,
                amount0Desired: lpAmount,
                amount1Desired: 0,  // Single-sided
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 1 hours
            });
            
            (uint256 tokenId, uint128 liquidity,,) = POSITION_MANAGER.mint(params);

            // Calculate pBAO amount based on liquidity
            uint256 pBAOToMint = uint256(liquidity);  // 1:1 ratio of liquidity to pBAO

            // Mint pBAO tokens
            pBAO.mint(address(this), pBAOToMint);

            // Lock LP token in lpLocker
            uint256 lockExpiry = block.timestamp + tierLockPeriods[contributorTiers[i]];
            
            // Transfer LP NFT to locker
            POSITION_MANAGER.safeTransferFrom(address(this), address(lpLocker), tokenId);
            lpLocker.depositAndLock(address(POSITION_MANAGER), tokenId, lockExpiry);

            // Lock pBAO tokens in pBAOLocker
            ERC20(address(pBAO)).approve(address(pBAOLocker), pBAOToMint);
            pBAOLocker.depositAndLock(address(pBAO), pBAOToMint, lockExpiry);

            // Store the pBAO amount corresponding to this LP position
            lpToPBAOAmount[tokenId] = pBAOToMint;

            emit LPPositionLocked(tokenId, contributor, contributorTiers[i], lockExpiry);
            emit PBAOLocked(contributor, pBAOToMint, lockExpiry);
        }

        emit FundraisingFinalized(true);
        fundraisingFinalized = true;

        // Transfer ownership to 0 address so no more tokens can be minted
        token.renounceOwnership();
    }

    function refund() external nonReentrant {
        require(!goalReached, "Fundraising goal was reached");
        require(block.timestamp > fundraisingDeadline, "Deadline not reached yet");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit Refund(msg.sender, contributedAmount);
    }

    function execute(address[] calldata contracts, bytes[] calldata data, uint256[] calldata msgValues)
        external
        onlyOwner
    {
        require(fundraisingFinalized, "Fundraising not finalized");
        require(contracts.length == data.length && data.length == msgValues.length, "Array lengths mismatch");

        for (uint256 i = 0; i < contracts.length; i++) {
            (bool success,) = contracts[i].call{value: msgValues[i]}(data[i]);
            require(success, "Call failed");
        }
    }

    function extendFundExpiry(uint256 newFundExpiry) external onlyOwner {
        require(newFundExpiry > fundExpiry, "Must choose later fund expiry");
        fundExpiry = newFundExpiry;
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

    receive() external payable {
        if (!goalReached && block.timestamp < fundraisingDeadline) {
            contribute();
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Unstake both LP tokens and corresponding pBAO tokens from their respective HoneyLockers
     * @param tokenId The ID of the LP token to unstake
     */
    function unstakeTokens(uint256 tokenId, address lpStakingContract, address pBAOStakingContract) external nonReentrant {
        // Check if caller is the original owner of the LP position
        (address owner,,,,,,,,,, ) = POSITION_MANAGER.positions(tokenId);
        require(msg.sender == owner, "Not the LP token owner");

        // Get the amount of pBAO tokens corresponding to this LP position
        uint256 pBAOAmount = lpToPBAOAmount[tokenId];
        require(pBAOAmount > 0, "No pBAO tokens found for this LP");

        // First unstake LP tokens from lpLocker
        lpLocker.unstake(
            address(POSITION_MANAGER), 
            lpStakingContract,
            tokenId, 
            ""
        );

        // Then withdraw LP tokens
        lpLocker.withdrawLPToken(address(POSITION_MANAGER), tokenId);

        // First unstake pBAO tokens from pBAOLocker
        pBAOLocker.unstake(
            address(pBAO),
            pBAOStakingContract,
            pBAOAmount,
            ""
        );

        // Then withdraw pBAO tokens
        pBAOLocker.withdrawLPToken(address(pBAO), pBAOAmount);

        // Clear the mapping
        delete lpToPBAOAmount[tokenId];

        emit TokensUnstaked(tokenId, msg.sender, pBAOAmount);
    }
}