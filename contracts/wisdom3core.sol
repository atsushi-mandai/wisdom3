// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./token/ERC20/Wisdom3Token.sol";
import "./access/Ownable.sol";
import "./utils/math/SafeMath.sol";

/// @title Wisdom3core
/// @author Atsushi Mandai
/// @notice Basic functions of the Wisdome3 will be written here.
contract Wisdom3Core is Wisdom3Token, Ownable {

    using SafeMath for uint256;

    /**
    *
    *
    * Events of Wisdom3Core
    *
    *
    */

    event AnnotationCreated(uint annotationId, string url, string body, string languageCode);


    /**
    *
    *
    * Variables of Wisdom3Core
    *
    *
    */

    /**
    * @dev basicFee is used to determine the amount of WSDM paid
    * by the reader who wants to read the annotations.
    * basicFee should be determined by a vote of governance token holders in the future
    */
    uint basicFee = 1;

    /**
    * @dev When the curator stakes his/her WSDM to an annotation,
    * it cannot be pulled out until the minimumStakePeriod has elapsed. 
    * This prevents malicious front-end providers from proactively staking to an annotation 
    * just before it is purchased by the reader.
    * basicFee should be determined by a vote of governance token holders in the future
    */
    uint32 minimumStakePeriod = 30 days;
    
    /**
    * @dev "annotation" is the basic structure of Wisdom3.
    * Each annotation should be made to a specific URL to add an annottation
    * to the content on the web.
    * For languageCode, ISO 639-1 should be used. 
    * The body of each annotation is retained in an internal mapping so that 
    * it is only disclosed to the user who paid the WSDM for it.
    */
    struct annotation {
        string url;
        string languageCode;
        address author;
        uint totalStake;
    }
    annotation[] public annotations;
    mapping(uint => string) internal annotationBody;

    /**
    * @dev Each annotation could be staked with WSDM.
    * Annotation with more stakes of WSDM are considered more valuable annotation.
    * Therefore, it will be displayed preferentially, 
    * and the author & curator of it will receive more rewards.
    */
    struct annotationStake {
        uint annotationId;
        uint amount;
        address curatorAddress;
        uint32 withdrawAllowTime;
    }
    annotationStake[] public annotationStakes;

    /*
    *
    *
    * Modifiers of Wisdom3Core
    *
    *
    */

    modifier onlyStakeOwner(uint _stakeId) {
        require(_msgSender() == annotationStakes[_stakeId].curatorAddress);
        _;
    }


    /**
    *
    *
    * Public / External functions of Wisdom3Core
    *
    *
    */

    /**
    * @dev changeBasicFee function lets contract owner to change the basicFee.
    * changeMiniumStakePeriod function lets contract owner to change the minimumStakePeriod.
    * Owner of the contract will be transfered to the community in the future.
    * If few readers pay WSDM to read the annotations, the basic fee should be reduced to stimulate demand.
    * Conversely, if many readers pay WSDM to read the annotations, the community could conversely raise the 
    * basicFee to encourage readers to buy more WDSM. 
    */
    function changeBasicFee(uint _newBasicFee) public onlyOwner {
        basicFee = _newBasicFee;
    }  

    function changeMinimumStakePeriod(uint32 _newMinimumStakePeriod) public onlyOwner {
        minimumStakePeriod = _newMinimumStakePeriod;
    }

    /**
    * @dev "createAnnotation" lets anyone to create an annotation.
    */
    function createAnnotation(string memory _url, string memory _body, string memory _languageCode) public {
        annotations.push(annotation(_url, _languageCode, _msgSender(), 0));
        uint annotationId = annotations.length - 1;
        annotationBody[annotationId] = _body;
        emit AnnotationCreated(annotationId, _url, _body, _languageCode);
    }


    /*
    * @dev _withdrawStake lets curator withdraw his/her staked WSDM from an annotation.
    * A curator could only withdraw his/her stake after the minimumStakePeriod has passed.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function withdrawStake(uint _stakeId) public onlyStakeOwner(_stakeId) {
        require(uint32(block.timestamp) > annotationStakes[_stakeId].withdrawAllowTime);
        uint currentStake = annotationStakes[_stakeId].amount;
        uint annotationId = annotationStakes[_stakeId].annotationId;
        annotations[annotationId].totalStake = annotations[annotationId].totalStake - currentStake;
        annotationStakes[_stakeId].amount = currentStake;
    }

    /**
    * @dev getAnnotation function is for readers to get annotations.
    * reader could select how many annotations they want to read.
    function getAnnotations()
    */


    /**
    *
    *
    * Private / Internal functions of Wisdom3Core
    *
    *
    */

    /**
    * @dev _stakeToAnnotation is an internal function to be called
    * after the transaction has been checked from several perspectives.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function _stakeToAnnotation(uint _annotationId, uint _amount) internal {
        annotationStakes.push(annotationStake(_annotationId, _amount, _msgSender(), uint32(block.timestamp) + minimumStakePeriod));
        annotations[_annotationId].totalStake = annotations[_annotationId].totalStake + _amount;
    }

}