// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NeonToken.sol";

contract NeonStakingRewards {
    IERC20 public immutable stakingToken;
    NeonToken public immutable rewardsToken;

    address public owner; // person who'll set up a staking period and rewards amount

    // state var-s that keep track users rewards
    uint public duration;
    uint public finishAt; // when a reward finish
    uint public updatedAt; // when a reward was updated
    uint public rewardRate; // a reward earned by user per second
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    // state var-s that keep track total supply of the staked token, and amount of staked token per user
    uint public totalSupply;
    mapping(address => uint) public stakedUserAmount;

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = NeonToken(_rewardsToken);
    }

    // owner can set up a duration when rewards will be earned
    function setRewardsDuration(uint256 _duration) external {

    }

    // owner set up a reward amount to be paid for the duration
    function setRewardRate(uint256 _amount) external {
        
    }

    // user can stake token amount 
    function stake(uint256 _amount) external {

    }

    // user can withdraw his staked token amount
    function withdraw(uint256 _amount) external {

    }

    // function that is return the amount of earned reward tokens for the account
    function earn(address _staker) external view returns(uint256 _amount) {

    }
 
    // stakers can claim their rewards
    function claimReward() external {

    }

}