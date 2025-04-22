// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the necessary OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  // ERC20 standard implementation for the token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  // ERC20 interface for interacting with other ERC20 tokens
import "@openzeppelin/contracts/access/Ownable.sol";  // To implement the "Ownable" contract for ownership control

/// @title MyToken - Token ya staking
// Contract ikora token ikurikiza standard ya ERC20, izakoreshwa muri staking
contract MyToken is ERC20 {
    // Constructor ikora token izitwa "TestToken" ifite symbol "TTK", hanyuma iha deployer tokens
    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());  // Deployer ahabwa tokens 1,000,000
    }
}


/// @title StakingPool - Contract ya staking
// Contract izafasha abakoresha gushyira tokens muri staking no kubona inyungu (APR).
contract StakingPool is Ownable {
    // Iyi ni interface ya ERC20 izatuma dushobora gukorana na token zindi
    IERC20 public stakingToken;
    
    // APR (Annual Percentage Rate), ikeneye kuba 10%
    uint256 public rewardRate = 10; 
    
    // Umubare w’amasegonda mu mwaka, kugirango dushobore kubara inyungu (rewards)
    uint256 public constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;  
    
    // Igihe cy’amasegonda user ashobora kuguma muri staking atari ho penalty (7 days)
    uint256 public lockTime = 7 days;

    // Structure ikubiyemo amakuru ajyanye na stake ya buri user
    struct StakeInfo {
        uint256 amount;  // Umubare w’amafaranga user yashyizemo muri staking
        uint256 startTime;  // Igihe yo gushyira amafaranga muri staking
    }

    // Mapping uhuza address ya user na StakeInfo yabo
    mapping(address => StakeInfo) public stakers;

    // Constructor itanga token izakoreshwa muri staking
    constructor(address _stakingToken) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid token address");  // Genzura ko token itari kuri zero address
        stakingToken = IERC20(_stakingToken);  // Seta token izakoreshwa muri staking
    }

    /// @notice Users bashyira tokens muri staking
    // Fungura amafaranga muri staking
    function stake(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");  // Genzura ko amount atari zero
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");  // Kohereza tokens muri contract

        StakeInfo storage data = stakers[msg.sender];  // Fata amakuru ya stake ya user
        data.amount += _amount;  // Ongera umubare w'amafaranga user yashyizemo
        data.startTime = block.timestamp;  // Seta igihe cyatangiye staking
    }

    /// @notice Babarira inyungu hashingiwe ku gihe
    // Fungura reward hashingiwe ku gihe user amaze muri staking
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory data = stakers[user];  // Fata amakuru ya stake ya user
        if (data.amount == 0) return 0;  // Niba nta stake user afite, reward ni zero

        uint256 timeStaked = block.timestamp - data.startTime;  // Kubara igihe user amaze muri staking
        uint256 reward = (data.amount * rewardRate * timeStaked) / (100 * SECONDS_IN_YEAR);  // Kubara reward
        return reward;  // Garura reward
    }

    /// @notice Users bakuramo tokens na rewards, harimo penalty niba hakiri kare
    // Fungura tokens zashyizwe muri staking hamwe na reward (inyungu)
    function unstake() external {
        StakeInfo storage data = stakers[msg.sender];  // Fata amakuru ya stake ya user
        require(data.amount > 0, "No stake");  // Genzura ko user afite stake

        uint256 duration = block.timestamp - data.startTime;  // Kubara igihe user amaze muri staking
        uint256 reward = calculateReward(msg.sender);  // Kubara inyungu
        uint256 toSend = data.amount;  // Umubare w'amafaranga user afite muri staking

        if (duration < lockTime) {
            uint256 penalty = (toSend * 10) / 100;  // Slashing penalty: niba avuye mbere y'igihe cyagenwe (lockTime)
            toSend -= penalty;  // Fungura amount irimo penalty
        }

        delete stakers[msg.sender];  // Siba amakuru ya stake ya user

        require(stakingToken.transfer(msg.sender, toSend + reward), "Transfer failed");  // Kohereza tokens + inyungu (reward) user
    }

    /// @notice Admin ashobora guhindura reward rate
    // Fungura reward rate kuri admin gusa
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;  // Hindura rate y'inyungu
    }

    /// @notice Admin ashobora guhindura lockTime
    // Fungura lock time kuri admin gusa
    function setLockTime(uint256 _newTime) external onlyOwner {
        lockTime = _newTime;  // Hindura igihe cya lock
    }
}
