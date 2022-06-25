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
    * basicFee should be determined by a vote of community in the future
    */
    uint basicFee = 1;

    /**
    * @dev mintPace defines the pace at which new WSDMs are mint.
    * It is determined by community governance between 80% and 120%.
    */
    uint8 mintPace = 100;

    /**
    * @dev When the curator stakes his/her WSDM to an annotation,
    * it cannot be pulled out until the minimumStakePeriod has elapsed. 
    * This prevents malicious front-end providers from proactively staking to an annotation 
    * just before it is purchased by the reader.
    * basicFee should be determined by a vote of community in the future
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
        string abst;
        string languageCode;
        address author;
        uint totalStake;
    }
    annotation[] public annotations;
    mapping(uint => string) internal annotationToBody;

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

    /**
    * @dev stakeExistance is a mapping which manages whether 
    * the curator already has an annotationStake associated with the annotation.
    * Key of the mapping is the hash of curator's address and annotationId combined.
    * Check _combineWithSender for detailed information.
    */
    mapping(bytes32 => bool) internal stakeExistance;


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
    * changeMintPace function lets contract owner to change the mintPace.
    * changeMiniumStakePeriod function lets contract owner to change the minimumStakePeriod.
    * Owner of the contract will be transfered to the community in the future.
    * If few readers pay WSDM to read the annotations, the basic fee should be reduced to stimulate demand.
    * Conversely, if many readers pay WSDM to read the annotations, the community could conversely raise the 
    * basicFee to encourage readers to buy more WDSM. 
    */
    function changeBasicFee(uint _newBasicFee) public onlyOwner {
        basicFee = _newBasicFee;
    }  

    function changeMintPace(uint8 _newMintPace) public onlyOwner {
        require(_newMintPace >= 80);
        require(_newMintPace <= 120);
        mintPace = _newMintPace;
    }

    function changeMinimumStakePeriod(uint32 _newMinimumStakePeriod) public onlyOwner {
        minimumStakePeriod = _newMinimumStakePeriod;
    }

    /**
    * @dev "createAnnotation" lets anyone to create an annotation.
    */
    function createAnnotation(string memory _url, string memory _abst, string memory _body, string memory _languageCode) public {
        annotations.push(annotation(_url, _abst, _languageCode, _msgSender(), 0));
        uint annotationId = annotations.length - 1;
        annotationToBody[annotationId] = _body;
        emit AnnotationCreated(annotationId, _url, _body, _languageCode);
    }

    /**
    * @dev checkStakeExistance lets curator check if he/she already has a stake to the annotation.
    * If he/she already has one, addStake should be used, not createStake.
    */
    function checkStakeExistance(uint _annotationId) public view returns(bool) {
        return stakeExistance[_combineWithSender(_annotationId)];
    }

    /**
    * @dev "createStake" lets anyone to create a stake to any annotation.
    * Curator could only have one stake to each annotation.
    * addStake should be used instead if the curator already has a stake to the annotation.
    */
    function createStake(uint _annotationId, uint _amount) public {
        require(checkStakeExistance(_annotationId) == false);
        //WSDM transfer function to be written here.
        _createStake(_annotationId, _amount);
    }

    /**
    * @dev addStake lets curator to add an additional WSDM to his/her stake.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function addStake(uint _stakeId, uint _amount) public onlyStakeOwner(_stakeId) {
        //WSDM transfer function to be written here.
        uint currentStake = annotationStakes[_stakeId].amount;
        uint annotationId = annotationStakes[_stakeId].annotationId;
        annotations[annotationId].totalStake = annotations[annotationId].totalStake + _amount;
        annotationStakes[_stakeId].amount = currentStake + _amount;
        annotationStakes[_stakeId].withdrawAllowTime = annotationStakes[_stakeId].withdrawAllowTime + minimumStakePeriod;
    }

    /**
    * @dev withdrawStake lets curator withdraw his/her staked WSDM from an annotation.
    * A curator could only withdraw his/her stake after the minimumStakePeriod has passed.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function withdrawStake(uint _stakeId) public onlyStakeOwner(_stakeId) {
        require(uint32(block.timestamp) > annotationStakes[_stakeId].withdrawAllowTime);
        uint currentStake = annotationStakes[_stakeId].amount;
        uint annotationId = annotationStakes[_stakeId].annotationId;
        annotations[annotationId].totalStake = annotations[annotationId].totalStake - currentStake;
        annotationStakes[_stakeId].amount = currentStake;
        //WSDM transfer function to be written here.
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
    * @dev checkStakeExistance lets curator check if he/she already has a stake to the annotation.
    * If he/she already has one, addStake should be used, not createStake.
    */
    function _combineWithSender(uint _annotationId) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), _annotationId));
    }

    /**
    * @dev _createStake is a private function to be called
    * after the transaction has been checked from several perspectives.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function _createStake(uint _annotationId, uint _amount) private {
        annotationStakes.push(annotationStake(_annotationId, _amount, _msgSender(), uint32(block.timestamp) + minimumStakePeriod));
        annotations[_annotationId].totalStake = annotations[_annotationId].totalStake + _amount;
        stakeExistance[_combineWithSender(_annotationId)] = true;
    }

    /**
    * @dev _mintByAnnotate is called from within the createAnnotation function.
    * It issues new WSDM and sends it to the annotation creator.
    */
    function _mintByAnnotate() internal {
        //mint and send function here
    }

    /**
    * @dev _mintForCurator is called from within the ***** function.
    * It issues new WSDM and sends it to the curator when the annotation is purchased.
    */
    function _mintForCurator() internal {
        //mint and send function here
    }

}