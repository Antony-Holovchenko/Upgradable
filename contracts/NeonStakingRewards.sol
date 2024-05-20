// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NeonToken.sol";

contract NeonStakingRewards is Initializable, OwnableUpgradeable{
   /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable stakingToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    NeonToken public immutable rewardsToken;

    // var-s that keep track users rewards
    uint256 public rewardDuration; // duration of the rewarding (in seconds)
    uint256 public rewardFinishAt; // when a rewarding is finished
    uint256 public rewardRateUpdatedAt;  // when a rewardRate was updated
    uint256 public rewardRate; // a reward paid to user (per second)
    uint256 public rewardPerTokenStored; //Sum of (reward rate * dt * 1e18 / total supply)
    // user address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // user address => rewards that user received
    mapping(address => uint256) public rewards;
    uint256 public totalSupply; //Total staked amount
    // User address => staked amount
    mapping(address => uint256) public stakedUserAmount;

    function initialize() external initializer{
        __Ownable_init(msg.sender);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = NeonToken(_rewardToken);
    }

    /**
     * @dev Update the reward for a specific staker.
     * @param _staker - account which balance should be updated.
     */
    modifier updateReward(address _staker) {
        rewardPerTokenStored = calculateRewardPerToken();
        rewardRateUpdatedAt = lastTimeRewardApplicable();

        if (_staker != address(0)) {
            rewards[_staker] = getEarnedAmount(_staker);
            userRewardPerTokenPaid[_staker] = rewardPerTokenStored;
        }

        _;
    }

    /**
     * @dev Return the timestamp, when the last reward is still available.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(rewardFinishAt, block.timestamp);
    }

     /**
     * @dev Calculate the current reward per token. 
     */
    function calculateRewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored
            + (rewardRate * (lastTimeRewardApplicable() - rewardRateUpdatedAt) * 1e18)
                / totalSupply;
    }

    /**
     * @dev Call to return the amount of earned reward tokens for the account.
     * The earned amount is calculated by the next formula: amount of all staked user tokens *
     * (reward per token - user reward per token paid) + previous user rewards.
     * 
     * @param _staker - account which earned rewards.
     */
    function getEarnedAmount(address _staker) public view returns (uint256) {
        uint256 stakedAmount = stakedUserAmount[_staker];
        uint256 userRewardPerToken = userRewardPerTokenPaid[_staker];
        
        return ((stakedAmount * (calculateRewardPerToken() - userRewardPerToken)) / 1e18) + rewards[_staker];
    }

    /**
     * @dev Return minimum number between 2 values. 
     * @param x - 1st number 
     * @param y - 2nd number
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Call this function to stake tokens amount.
     * @param _amount - value of the tokens to stake.
     */ 
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakedUserAmount[msg.sender] += _amount;
        totalSupply += _amount;
    }
    
    /**
     * @dev Call this function to withdraw staked tokens amount.
     * @param _amount - value of the tokens to withdraw.
     */
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakedUserAmount[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    /**
    * @dev Call this function to claim rewards, received for staking.
    */
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    /**
     * @dev Set up a rewards duration. Only owner can call this function.
     * @param _duration  - period during which rewards can be earned.
     */
    function setRewardDuration(uint256 _duration) external onlyOwner {
        // make sure that owner can update reward duration, only when the previous period is finished
        require(rewardFinishAt < block.timestamp, "reward duration not finished");
        rewardDuration = _duration;
    }

    /**
     * @dev Set up a reward amount. Function will send a reward tokens into
     * this contract, and set a reward rate. Only owner can call this function.
     * @param _amount - amount of tokens that will be used for a reward.
     */
    function setRewardAmount(uint256 _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        // checking if the rewardDuration already expired, or not started
        if (block.timestamp >= rewardFinishAt) {
            rewardRate = _amount / rewardDuration; 
        } else { // rewards duration is not finished yet --> 1st calculate the amount of the remaining rewards, 2nd add remaining amount to the amount we set in parameter to set up a reward rate
            // Mul rewardRate by the time until the rewards ends(finishAt - current time)
            uint256 remainingRewards = (rewardFinishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / rewardDuration;
        }

        require(rewardRate > 0, "reward rate = 0");
        //checking that it is enough reward token in this contract, to pay rewards
        require(
            rewardRate * rewardDuration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        rewardFinishAt = block.timestamp + rewardDuration;
        rewardRateUpdatedAt = block.timestamp;
    }
}