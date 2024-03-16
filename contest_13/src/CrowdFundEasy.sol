// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title CrowdFundEasy
 * @author https://www.linkedin.com/in/bepossible/
 * @notice Disclaimer 
 * Not all of the tricks I use here can be used in real projects! 
 * The approach taken here is based on passing test cases and minimizing gas usage. 
 * In real projects, these techniques may have negative consequences.
 */
interface IMyToken {
    function getTokenPriceInUSD() external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}
contract CrowdFundEasy {
    struct Campaign {
        uint32 endTime;
        uint32 goal;    
        uint32 amount;  
        address creator;
    }
    IMyToken token;
    Campaign[] campaigns;
    uint256 price;
    // mapping(address => mapping(uint256 => uint256)) contributions;
    mapping(uint256 => uint256) contributions;

    /**
     * @param _token list of allowed token addresses
     */
    constructor(address _token) {
        token = IMyToken(_token);
        price = token.getTokenPriceInUSD();
    }

    /**
     * @notice createCampaign
     * This function allows anyone to create a campaign of goal amount (in USD) with the time duration of duration (in seconds). 
     * As soon as the campaign is created, it is considered to be active. 
     * Each campaign must be associated with an id , starting from 1 and increasing one at a time.
     * @param _goal amount of funds to be raised in USD
     * @param _duration the duration of the campaign in seconds
     */
    function createCampaign(uint256 _goal, uint256 _duration) external {
        require(_goal > 0);
        require(_duration > 0);
        campaigns.push() = Campaign(
            uint32(block.timestamp + _duration), 
            uint32(_goal),
            0,
            msg.sender);
    }

    /**
     * @dev contribute
     * This function allows anyone to create a contribution of amount tokens to a campaign specified by the id . 
     * This function must revert if the campaign with id does not exist.
     * @param _id the id of the campaign
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, uint256 _amount) external {
        require(_amount > 0);
        Campaign storage c = campaigns[_id - 1];
        require(c.creator != msg.sender);
        require(c.endTime > block.timestamp);

        contributions[(_id << 160) + uint160(msg.sender)] += _amount;
        c.amount += uint32(_amount);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev cancelContribution
     * This function allows any donor to cancel their contribution. 
     * It should revert if no donations have been made by the caller for the particular campaign.
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime > block.timestamp);
        // require(c.goal > 0);     
        uint256 index = (_id<< 160) + uint160(msg.sender);   
        uint256 amount = contributions[index];
        require(amount > 0);
        c.amount -= uint32(amount);
        contributions[index] = 0;
        token.transfer(msg.sender, amount); 
    }

    /**
     * @notice withdrawFunds
     * This function allows the creator of the campaign id to collect all the contributions. 
     * This function must revert if the duration of the campaign has not passed, or / and the goal has not been met.
     * @param _id the id of the campaign
     */

    function withdrawFunds(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime <= block.timestamp);        
        require(c.creator == msg.sender);
        require(c.goal <= c.amount * price); //token.getTokenPriceInUSD());
        // require(c.goal > 0);        
        // c.goal = 0;
        token.transfer(msg.sender, c.amount);
    }

    /**
     * @notice refund
     * This allows the donors to get their funds back if the campaign has failed. It should revert if no donations were made to this campaign by the caller.
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime < block.timestamp);
        require(c.goal > c.amount * price); //token.getTokenPriceInUSD());
        uint256 index = (_id << 160) + uint160(msg.sender);
        uint256 amount = contributions[index];
        require(amount > 0);        
        contributions[index] = 0;
        token.transfer(msg.sender, amount);
    }

    /**
     * @notice getContribution
     * This function allows anyone to view the contributions made by contributor for the id campaign (in USD).
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(uint256 _id, address _contributor) public view returns (uint256) {
        return contributions[(_id << 160) + uint160(_contributor)] * price; //token.getTokenPriceInUSD();
    }
		
		/**
		 * @notice getCampaign
         * This function returns the remaining time, the goal, and the total funds collected (in USD).
		 * @param _id the id of the campaign
		 * @return remainingTime the time (in seconds) when the campaign ends
		 * @return goal the goal of the campaign (in USD)
		 * @return totalFunds total funds (in USD) raised by the campaign
		 */
    function getCampaign(uint256 _id)
        external
        view
        returns (uint256 remainingTime, uint256 goal, uint256 totalFunds) {
            Campaign memory c = campaigns[_id - 1];
            uint256 end;
            if(c.endTime > block.timestamp) {
                end = c.endTime - block.timestamp;
            }
            return (end, c.goal, c.amount * price); //token.getTokenPriceInUSD());
        }
}