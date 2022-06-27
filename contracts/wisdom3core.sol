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
    * basicFee should be determined by a vote of community in the future.
    */
    uint public basicFee = 1;

    /**
    * @dev While the totalSupply of WSDM is below annotationMintCap,
    * the protocol rewards the author with annotationMintAmount of WSDM everytime an annotation is created.
    * Default annotationMintAmount is 2WSDM, and it should be determined by a vote of community in the future.
    */
    uint public createAnnotationMintCap = 20000000 * 10**decimals();
    uint public createAnnotationMintAmount = 2 * 10**decimals();

    /**
    * @dev Everytime a new stake is created to an annotation,
    * the protocol rewards the author with (cap - totalSupply) / createStakeMintDenominator amount of WSDM.
    * creatorStakeMintDenominator could not be changed.
    */
    uint public createStakeMintDenominator = 2 * 10**(decimals() + 10);

    /**
    * @dev minimumStake determines the minimum amount of WSDM that could be staked.
    * It will be determined by community governance
    */
    uint public minimumStake = 10 ** decimals();

    /**
    * @dev When the curator stakes his/her WSDM to an annotation,
    * it cannot be pulled out until the minimumStakePeriod has elapsed. 
    * This prevents malicious front-end providers from proactively staking to an annotation 
    * just before it is purchased by the reader.
    * It will be determined by a vote of community in the future
    */
    uint32 minimumStakePeriod = 30 days;

    /**
    * @dev distributionRatio determines how much of the WSDM payed by the reader of an annotation
    * will be payed to each contributor. Sum of the ratios should be 100.
    * distributionRatio[0] => Author
    * distributionRatio[1] => Curator
    * distributionRatio[2] => Broaker
    */
    uint8[3] public distributionRatio = [80,10,10];
    
    /**
    * @dev "annotation" is the basic structure of Wisdom3.
    * Each annotation should be made to a specific URL to add an annottation
    * to the content on the web.
    * For languageCode, ISO 639-1 should be used. 
    * The body of each annotation is retained in an internal mapping so that 
    * it is only disclosed to the user who paid the WSDM for it.
    * annotationPurchased records whether the sender has purchased the rights 
    * to read the body of an annotation or not.
    */
    struct Annotation {
        string url;
        string abst;
        string languageCode;
        address author;
        uint totalStake;
        uint createdAt;
    }
    Annotation[] public annotations;
    mapping(uint => string) internal annotationToBody;
    mapping(bytes32 => bool) public annotationPurchased;

    /**
    * @dev Each annotation could be staked with WSDM.
    * Annotation with more stakes of WSDM are considered more valuable annotation.
    * Therefore, it will be displayed preferentially, 
    * and the author & curator of it will receive more rewards.
    */
    struct Stake {
        uint annotationId;
        uint amount;
        address curatorAddress;
        uint32 withdrawAllowTime;
    }
    Stake[] public stakes;

    /**
    * @dev stakeExistance is a mapping which manages whether 
    * the curator already has an annotationStake associated with the annotation.
    * Key of the mapping is the hash of curator's address and annotationId combined.
    * Check _combineWithSender for detailed information.
    */
    mapping(bytes32 => bool) internal stakeExistance;

    /**
    * @dev Profile of the Author.
    */
    struct Author {
        address authorAddress;
        uint authorAnnotations;
        uint authorStakes;
        uint authorStakedAmount;
        uint authorPurchased;
        uint nextAvailableTime;
    }
    mapping(address => Author) public addressToAuthor;

    /**
    * @dev Review of the annotation by the purchaser.
    */
    struct Review {
        uint annotationId;
        string review;
        bool like;
        address reviewer;
    }
    Review[] public reviews;

    /*
    *
    *
    * Modifiers of Wisdom3Core
    *
    *
    */

    modifier onlyStakeOwner(uint _stakeId) {
        require(_msgSender() == stakes[_stakeId].curatorAddress);
        _;
    }

    modifier onlyPurchaser(uint _annotationId) {
        require(annotationPurchased[_combineWithSender(_annotationId)] == true);
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
    * @dev These functions lets the owner of the contract change the basic variables of the project.
    * Owner of the contract will be transfered to the community in the future.
    * If there are high demands for annotations,
    *  - basicFee should be lifted upwards to encourage readers to buy more WSDM
    *  - mintPace should be slowed down to supply less WSDM and raise the price of WSDM.
    * Conversely, if the demand for annotations are low,
    *  - basicFee should be reduced to stimulate the demand for annotations.
    *  - mintPace should be accelerated to supply more WSDM and stimulate the demand for annotations.
    */
    function changeBasicFee(uint _newBasicFee) public onlyOwner {
        basicFee = _newBasicFee;
    }  

    function changeCreateAnnotationMintAmount(uint _newMintAmount) public onlyOwner {
        createAnnotationMintAmount = _newMintAmount;
    }

    function changeMinimumStake(uint8 _newMinimumStake) public onlyOwner {
        minimumStake = _newMinimumStake;
    }

    function changeMinimumStakePeriod(uint32 _newMinimumStakePeriod) public onlyOwner {
        minimumStakePeriod = _newMinimumStakePeriod;
    }

    function changeDistributionRatio(uint8 _author, uint8 _curator, uint8 _broaker) public onlyOwner {
        require(_author + _curator + _broaker == 100);
        //maybe require _author > 80 or something like that?
        distributionRatio[0] = _author;
        distributionRatio[1] = _curator;
        distributionRatio[2] = _broaker;
    }

    /**
    * @dev "createAnnotation" lets anyone to create an annotation.
    */
    function createAnnotation(string memory _url, string memory _abst, string memory _body, string memory _languageCode) public {
        require(addressToAuthor[_msgSender()].nextAvailableTime < block.timestamp, "Annotator must wait 1 hour before creating another annotation.");
        annotations.push(Annotation(_url, _abst, _languageCode, _msgSender(), 0, block.timestamp));
        uint annotationId = annotations.length - 1;
        annotationToBody[annotationId] = _body;
        addressToAuthor[_msgSender()].authorAnnotations++;
        addressToAuthor[_msgSender()].nextAvailableTime = addressToAuthor[_msgSender()].nextAvailableTime + 1 hours;
        if (totalSupply() <= createAnnotationMintCap) {
            _mint(_msgSender(),createAnnotationMintAmount);
            emit AnnotationCreated(annotationId, _url, _body, _languageCode);
        } else {
            emit AnnotationCreated(annotationId, _url, _body, _languageCode);
        }
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
        require(_amount >= minimumStake);
        _createStake(_annotationId, _amount);
    }

    /**
    * @dev addStake lets curator to add an additional WSDM to his/her stake.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function addStake(uint _stakeId, uint _amount) public onlyStakeOwner(_stakeId) {
        _addStake(_stakeId, _amount);
    }

    /**
    * @dev withdrawStake lets curator withdraw his/her staked WSDM from an annotation.
    * A curator could only withdraw his/her stake after the minimumStakePeriod has passed.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function withdrawStake(uint _stakeId) public onlyStakeOwner(_stakeId) {
        require(uint32(block.timestamp) > stakes[_stakeId].withdrawAllowTime);
        _withdrawStake(_stakeId);
    }

    /**
    * @dev purchaseBody function is for readers to purchase the right to get the body of an annotation.
    */

    function purchaseBody(uint _annotationId) public {
        //WSDM transfer function here.
        annotationPurchased[_combineWithSender(_annotationId)] = true;
        addressToAuthor[annotations[_annotationId].author].authorPurchased++;
        _mintForCurators();
    }

    /**
    * @dev getBody function is for readers to get the body of an annotation.
    * The reader first needs to purchase the rights to read the body first.
    */
    function getBody(uint _annotationId) public view onlyPurchaser(_annotationId) returns(string memory) {
        return annotationToBody[_annotationId];
    }

    /**
    * @dev addReview allows purchaser of an annotation to add a review to it.
    */
    function addReview(uint _annotationId, string memory _review, bool _like) public onlyPurchaser(_annotationId) {
        reviews.push(Review(_annotationId, _review, _like, _msgSender()));
    }


    /**
    *
    *
    * Private / Internal functions of Wisdom3Core
    *
    *
    */

    /**
    * @dev combineWithSender combines annotationId with sender's address and outputs unique bytes32.
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
        transferFrom(_msgSender(), address(this), _amount);
        stakes.push(Stake(_annotationId, _amount, _msgSender(), uint32(block.timestamp) + minimumStakePeriod));
        annotations[_annotationId].totalStake = annotations[_annotationId].totalStake + _amount;
        stakeExistance[_combineWithSender(_annotationId)] = true;
        addressToAuthor[annotations[_annotationId].author].authorStakedAmount = addressToAuthor[annotations[_annotationId].author].authorStakedAmount + _amount;
        _mint(annotations[_annotationId].author, (cap() - totalSupply()) / createStakeMintDenominator);
    }

    /**
    * @dev _addStake is a private function to be called from addStake.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function _addStake(uint _stakeId, uint _amount) private {
        transferFrom(_msgSender(), address(this), _amount);
        uint currentStake = stakes[_stakeId].amount;
        uint annotationId = stakes[_stakeId].annotationId;
        annotations[annotationId].totalStake = annotations[annotationId].totalStake = annotations[annotationId].totalStake = annotations[annotationId].totalStake + _amount;
        stakes[_stakeId].amount = currentStake + _amount;
        stakes[_stakeId].withdrawAllowTime = stakes[_stakeId].withdrawAllowTime + minimumStakePeriod;
        addressToAuthor[annotations[annotationId].author].authorStakedAmount = annotations[annotationId].totalStake = annotations[annotationId].totalStake + _amount;
    }

    /**
    * @dev _withdrawStake is a private function to be called from withdrawStake.
    * !!! better use SafeMath in this function but it doesn't work somehow.
    */
    function _withdrawStake(uint _stakeId) private {
        uint currentStake = stakes[_stakeId].amount;
        uint annotationId = stakes[_stakeId].annotationId;
        annotations[annotationId].totalStake = annotations[annotationId].totalStake - currentStake;
        addressToAuthor[annotations[annotationId].author].authorStakedAmount = addressToAuthor[annotations[annotationId].author].authorStakedAmount - currentStake;
        stakes[_stakeId].amount = 0;
        //WSDM transfer function to be written here.
    }

    /**
    * @dev _mintWhenStaked is called from within the createStake function.
    * It issues new WSDM and sends it to the author of the annotation.
    */
    function _mintWhenStaked() public view returns(uint) {
     //   uint amount = mintPace1;
     //   return amount;
    }

    /**
    * @dev _mintForCurator is called from within the ***** function.
    * It issues new WSDM and sends it to the curators when the annotation is purchased.
    */
    function _mintForCurators() public view returns(uint) {
     //   uint amount = (cap() - totalSupply()) * mintPace;
     //   return amount;
    }

}