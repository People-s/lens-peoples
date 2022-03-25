pragma solidity 0.8.10;

import {IFollowModule} from '../../../interfaces/IFollowModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidatorFollowModuleBase} from './FollowValidatorFollowModuleBase.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import 'hardhat/console.sol';

contract RequiredCurrencyNFTFollowModule is IFollowModule, FollowValidatorFollowModuleBase {
    mapping(uint256 => uint256) internal NFTReqAmount;

    mapping(uint256 => uint256) internal ERC20ReqAmount;

    mapping(uint256 => address) internal _NFTAddress;

    mapping(uint256 => address) internal _ERC20Address;

    address NFTaddress;

    constructor(address hub) ModuleBase(hub) {}

    function initializeFollowModule(uint256 profileId, bytes calldata data)
        external
        override
        onlyHub
        returns (bytes memory)
    {
        (address NFTAddress, uint256 NFTAmount, address ERC20Address, uint256 ERC20Amount) = abi
            .decode(data, (address, uint256, address, uint256));

        console.log('NFTAddress', NFTAddress);
        console.log('NFTAmount', NFTAmount);
        console.log('ERC20Address', ERC20Address);
        console.log('NFTERC20AmountAmount', ERC20Amount);

        if (NFTAmount != 0) {
            NFTReqAmount[profileId] = NFTAmount;
            _NFTAddress[profileId] = NFTAddress;
        }

        if (ERC20Amount != 0) {
            ERC20ReqAmount[profileId] = ERC20Amount;
            _ERC20Address[profileId] = ERC20Address;
        }

        return data;
    }

    function processFollow(
        address follower,
        uint256 profileId,
        bytes calldata data
    ) external view override {
        if (NFTReqAmount[profileId] != 0) {
            ERC721 NFTContract = ERC721(_NFTAddress[profileId]);

            uint256 userNFTAmount = NFTContract.balanceOf(follower);

            console.log('userNFTAmount', userNFTAmount);

            require(userNFTAmount >= NFTReqAmount[profileId], 'Not enough NFTS to follow!');
        }
        if (ERC20ReqAmount[profileId] != 0) {
            ERC20 ERC20Contract = ERC20(_ERC20Address[profileId]);

            uint256 userERC20Amount = ERC20Contract.balanceOf(follower);
            console.log('userERC20Amount', userERC20Amount);

            require(userERC20Amount >= ERC20ReqAmount[profileId], 'Not enough ERC20 to follow!');
        }
    }

    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external override {}
}
