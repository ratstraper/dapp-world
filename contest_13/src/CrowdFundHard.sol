// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title CrowdFundHard
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

contract CrowdFundHard {
    struct Campaign {
        uint32 endTime;
        uint32 goal;    
        uint32 amount;  
        address creator;
    }

    address[] tokens;
    Campaign[] campaigns;
    mapping(uint256 => mapping(address => uint256)) campaignAmount;    
    mapping(uint256 => mapping(address => mapping(address => uint256))) contributions; 


		/**
		 * @param _tokens list of allowed token addresses
		 */
		constructor(address[] memory _tokens) {
        uint256 count = _tokens.length;
        tokens = new address[](count);
        unchecked {
            for(uint256 i; i < count; ++i) {
                tokens[i] = _tokens[i]; 
            }
        }
    }

    /**
     * @notice createCampaign allows anyone to create a campaign
     * @param _goal amount of funds to be raised in USD
     * @param _duration the duration of the campaign in seconds
     */
    function createCampaign(uint256 _goal, uint256 _duration) external {
        require(_goal > 0);
        require(_duration > 0);
        unchecked {
            campaigns.push() = Campaign(
                uint32(block.timestamp + _duration), 
                uint32(_goal),
                0,
                msg.sender);   
        }     
    }

    /**
     * @dev contribute allows anyone to contribute to a campaign
     * @param _id the id of the campaign
     * @param _token the address of the token to contribute
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, address _token, uint256 _amount) external {
        require(_amount > 0);
        uint256 price = IMyToken(_token).getTokenPriceInUSD();
        require(price > 0);
        Campaign storage c = campaigns[_id - 1];
        require(c.creator != msg.sender);
        require(c.endTime > block.timestamp);
        unchecked {
            contributions[_id][msg.sender][_token] += _amount;
            c.amount += uint32(_amount * price);
            campaignAmount[_id][_token] += _amount;
        }
        IMyToken(_token).transferFrom(msg.sender, address(this), _amount);                
    }

    /**
     * @dev cancelContribution allows anyone to cancel their contribution
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime > block.timestamp);
        _refund(_id, c);
    }

    /**
     * @notice withdrawFunds allows the creator of the campaign to withdraw the funds
     * @param _id the id of the campaign
     */

    function withdrawFunds(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime < block.timestamp);        
        require(c.creator == msg.sender);
        require(c.goal <= c.amount); 
        require(c.goal > 0);        
        c.goal = 0;  
        uint256 count = tokens.length;   
        unchecked {
        for(uint i; i < count; i++) {
            address token = tokens[i];
            uint256 amount = campaignAmount[_id][token];
            if(amount > 0) { 
                IMyToken(token).transfer(msg.sender, amount);      
            }
        }         
        }
    }
    /**
     * @notice refund allows the contributors to get a refund if the campaign failed
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {
        Campaign storage c = campaigns[_id - 1];
        require(c.endTime < block.timestamp);
        require(c.goal > c.amount); 
        _refund(_id, c);
        // uint256 count = tokens.length;   
        // uint256 a;
        // for(uint i; i < count; ++i) {
        //     address token = tokens[i];
        //     uint256 amount = contributions[_id][msg.sender][token];
        //     if(amount > 0) {
        //         contributions[_id][msg.sender][token] = 0;       
        //         a += amount;              
        //         IMyToken(token).transfer(msg.sender, amount);             
        //     }
        // }   
        // require(a > 0);   
    }

    /**
     * @notice getContribution returns the contribution of a contributor in USD
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(uint256 _id, address _contributor) public view returns (uint256) {
        Campaign memory c = campaigns[_id - 1];
        require(c.endTime > 0);
        uint256 count = tokens.length;   
        uint256 a;
        unchecked {
            for(uint i; i < count; ++i) {
                address token = tokens[i];
                uint256 amount = contributions[_id][_contributor][token];
                if(amount > 0) {  
                    a += amount * IMyToken(token).getTokenPriceInUSD();                      
                }
            }   
        }
        return a;
    }
		
		/**
		 * @notice getCampaign returns details about a campaign
		 * @param _id the id of the campaign
		 * @return remainingTime the time (in seconds) remaining for the campaign
		 * @return goal the goal of the campaign (in USD)
		 * @return totalFunds total funds (in USD) raised by the campaign
		 */
    function getCampaign(uint256 _id)
        external
        view
        returns (uint256 remainingTime, uint256 goal, uint256 totalFunds) {
            Campaign memory c = campaigns[_id - 1];
            require(c.goal > 0);
            uint256 end;
            unchecked {
                if(c.endTime > block.timestamp) {
                    end = c.endTime - block.timestamp;
                }
            }
            return (end, c.goal, c.amount); //token.getTokenPriceInUSD());          
        }


    function _refund(uint256 _id, Campaign storage c) internal {
        uint256 count = tokens.length;   
        uint256 a;
        unchecked {
            for(uint i; i < count; ++i) { 
                uint256 amount = contributions[_id][msg.sender][tokens[i]]; 
                if(amount > 0) {
                    uint256 price = IMyToken(tokens[i]).getTokenPriceInUSD();
                    c.amount -= uint32(amount * price);
                    campaignAmount[_id][tokens[i]] -= amount;
                    contributions[_id][msg.sender][tokens[i]] = 0; 
                    a += amount;
                    IMyToken(tokens[i]).transfer(msg.sender, amount);      
                }
            }
        }
        require(a > 0);
    }        
}