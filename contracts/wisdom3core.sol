// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./token/ERC20/Wisdom3Token.sol";
import "./access/Ownable.sol";

/// @title Wisdom3core
/// @author Atsushi Mandai
/// @notice Basic functions of the Wisdome3 will be written here.
contract Wisdom3Core is Wisdom3Token, Ownable {

    event AnnotationCreated(uint annotationId, string url, string body, string languageCode);

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
    */
    struct annotation {
        string url;
        string body;
        string languageCode;
        address author;
    }
    annotation[] internal annotations;

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
    * @dev "createAnnotation" lets anyone to create an annotation.
    */
    function createAnnotation(string memory _url, string memory _body, string memory _languageCode) public {
        annotations.push(annotation(_url, _body, _languageCode, _msgSender()));
        uint annotationId = annotations.length - 1;
        emit AnnotationCreated(annotationId, _url, _body, _languageCode);
    }

    /**
    * @dev changeBasicFee function lets contract owner to change the basicFee.
    * Owner of the contract will be transfered to the community in the future.
    */
    function changeBasicFee(uint _newBasicFee) public onlyOwner {
        basicFee = _newBasicFee;
    }  

    
}