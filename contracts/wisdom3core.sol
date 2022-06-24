// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./token/ERC20/Wisdom3Token.sol";
import "./access/Ownable.sol";

/// @title Wisdom3core
/// @author Atsushi Mandai
/// @notice Basic functions of the Wisdome3 will be written here.
contract Wisdom3Core is Wisdom3Token, Ownable {

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
    */
    uint basicFee = 1;
    
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
    * Therefore, it will be displayed preferentially, and the author & curator of it will receive more rewards.
    */
    struct annotationStake {
        uint annotationId;
        address curatorAddress;
        uint stakeAmount;
    }
    annotationStake[] public annotationStakes;


    /**
    *
    *
    * Public / External functions of Wisdom3Core
    *
    *
    */

    /**
    * @dev changeBasicFee function lets contract owner to change the basicFee.
    * Owner of the contract will be transfered to the community in the future.
    * If few readers pay WSDM to read the annotations, the basic fee should be reduced to stimulate demand.
    * Conversely, if many readers pay WSDM to read the annotations, the community could conversely raise the 
    * basicFee to encourage readers to buy more WDSM. 
    */
    function changeBasicFee(uint _newBasicFee) public onlyOwner {
        basicFee = _newBasicFee;
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

    function _stakeToAnnotation(uint _id, uint _ammount) internal {

    }

    
}