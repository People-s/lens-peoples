// SPDX-License-Identifier: AGPL-3.0-only

import {ILensHub} from '../../../interfaces/ILensHub.sol';
import {DataTypes} from '../../../libraries/DataTypes.sol';
import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

pragma solidity 0.8.10;

contract PeoplesChannel {
    ILensHub immutable LENS_HUB;

    mapping(address => string[]) public ownerToHandles;
    mapping(address => bool) public isAllowed;
    mapping(string => string[]) public postsByChannel;
    mapping(address => bool) public isCreator;
    event newChannel(address indexed creator, string indexed channelName);

    event newChannelPost(
        address indexed creator,
        string indexed channelName,
        string contenURI,
        address collectModule,
        bytes collectModuleReturnData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 indexed timestamp
    );

    bytes empty = '';
    bytes[] emptyList = [empty];

    DataTypes.CreateProfileData[] profileProposals;

    event ChannelProposals(address indexed creator, string channelName);

    function createChannel(DataTypes.CreateProfileData calldata vars) external {
        // console.log('msgSender', msg.sender);
        ownerToHandles[msg.sender].push(vars.handle);
        // require(isAllowed[msg.sender], 'Not allowed to generate people channel');
        LENS_HUB.createProfile(vars);
        uint256 profileId = LENS_HUB.getProfileIdByHandle(vars.handle);
        // Automatically follow by creator the profile he just made TBD

        uint256[] memory profileIdList = new uint256[](1);
        profileIdList[0] = (profileId);

        LENS_HUB.follow(profileIdList, emptyList);
        emit newChannel(msg.sender, vars.handle);
    }

    function createChannelProposal(DataTypes.CreateProfileData calldata vars) external payable {
        require(msg.value >= 0.10 ether, 'Not enough money to propose a channel');

        profileProposals.push(vars);
        emit ChannelProposals(msg.sender, vars.handle);
    }

    function confirmChannelProposal(uint256 proposalId) public {
        // Only owner or something

        this.createChannel(profileProposals[proposalId]);
    }

    constructor(address hub) {
        LENS_HUB = ILensHub(hub);
    }

    function createPost(DataTypes.PostData calldata vars) public {
        address followNFTAddress = LENS_HUB.getFollowNFT(vars.profileId);
        console.log('followNFTAddress', followNFTAddress);
        ERC721 NFTContract = ERC721(followNFTAddress);

        require(followNFTAddress != address(0), 'No one is following this channel');
        uint256 followNFT = NFTContract.balanceOf(msg.sender);
        console.log('followNFT', followNFT);
        require(followNFT >= 1, "Can't post if you are not accepted in channel");

        //This will make that all users that have followed the account cant pos from the profile
        console.log(msg.sender);

        string memory channelName = LENS_HUB.getHandle(vars.profileId);
        LENS_HUB.post(vars);
        emit newChannelPost(
            msg.sender,
            channelName,
            vars.contentURI,
            vars.collectModule,
            vars.collectModuleData,
            vars.referenceModule,
            vars.referenceModuleData,
            block.timestamp
        );
    }

    function getHandlesByOwner(address _owner) external view returns (string[] memory) {
        return ownerToHandles[_owner];
    }

    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleData
    ) public {
        string memory handle = LENS_HUB.getHandle(profileId);
        bool isOwner;
        for (uint256 i = 0; i < ownerToHandles[msg.sender].length; i++) {
            if (
                (keccak256(abi.encodePacked((ownerToHandles[msg.sender][i]))) ==
                    keccak256(abi.encodePacked((handle))))
            ) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, 'Only creator can set follow logic');
        LENS_HUB.setFollowModule(profileId, followModule, followModuleData);
    }

    receive() external payable {}

    ////
}
