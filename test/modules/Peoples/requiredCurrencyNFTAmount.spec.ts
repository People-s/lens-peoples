import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
    abiCoder,
    FIRST_PROFILE_ID,
    governance,
    lensHub,
    makeSuiteCleanRoom,
    MOCK_FOLLOW_NFT_URI,
    MOCK_PROFILE_HANDLE,
    MOCK_PROFILE_URI,
    userAddress,
    userTwo,
    userTwoAddress,
    requiredCurrencyNFTFollowModule,
    nftmock,
    currency
} from '../../__setup.spec';

makeSuiteCleanRoom('Peoples module for NFT/Currency Reqs for Following', function () {


    beforeEach(async function () {

        await expect(
            lensHub.createProfile({
                to: userAddress,
                handle: MOCK_PROFILE_HANDLE,
                imageURI: MOCK_PROFILE_URI,
                followModule: ZERO_ADDRESS,
                followModuleData: [],
                followNFTURI: MOCK_FOLLOW_NFT_URI,
            })
        ).to.not.be.reverted;
        await expect(
            lensHub.connect(governance).whitelistFollowModule(requiredCurrencyNFTFollowModule.address, true)
        ).to.not.be.reverted;
    });



    context.only('Negatives', function () {
        context('Initialization', function () {
            it('Should fail to initialize outside HUB ', async function () {
                await expect(
                    requiredCurrencyNFTFollowModule.initializeFollowModule(FIRST_PROFILE_ID, [])
                ).to.be.revertedWith(ERRORS.NOT_HUB);
            });
        });

        context('Failed Follows', function () {
            it('Follow should fail when calling it with addresses that doesnt have the required NFTs', async function () {

                const nftAddress = nftmock.address;

                const currencyAddress = currency.address;
                const quantityNFTs = 1;
                const reqCurrency = 5;

                const data = abiCoder.encode(
                    ['address', 'uint256', 'address', 'uint256'],
                    [nftAddress, quantityNFTs, currencyAddress, reqCurrency]);


                await expect(
                    lensHub.setFollowModule(FIRST_PROFILE_ID, requiredCurrencyNFTFollowModule.address, data)
                ).to.not.be.reverted;
                await expect(
                    lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])
                ).to.be.revertedWith('Not enough NFTS to follow!');
            });

            it('Approve should fail when sender has enough NFT but not enough currency', async function () {

                const nftAddress = nftmock.address;

                const currencyAddress = currency.address;
                const quantityNFTs = 1;
                const reqCurrency = 5;


                const data = abiCoder.encode(
                    ['address', 'uint256', 'address', 'uint256'],
                    [nftAddress, quantityNFTs, currencyAddress, reqCurrency]);


                await nftmock.connect(userTwo).mint();

                await expect(
                    lensHub.setFollowModule(FIRST_PROFILE_ID, requiredCurrencyNFTFollowModule.address, data)
                ).to.not.be.reverted;

                await expect(
                    lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])
                ).to.be.revertedWith('Not enough ERC20 to follow!');
            });
        });

        context('Correct Follows', function () {
            it('Follow should work when only NFT are needed and user has enough NFTs', async function () {


                const nftAddress = nftmock.address;

                const currencyAddress = ZERO_ADDRESS;
                const quantityNFTs = 1;
                const reqCurrency = 0;

                const data = abiCoder.encode(
                    ['address', 'uint256', 'address', 'uint256'],
                    [nftAddress, quantityNFTs, currencyAddress, reqCurrency]);


                await nftmock.connect(userTwo).mint();

                await expect(
                    lensHub.setFollowModule(FIRST_PROFILE_ID, requiredCurrencyNFTFollowModule.address, data)
                ).to.not.be.reverted;

                await expect(
                    lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])
                ).to.not.be.reverted;

            });

            it('Follow should work when user has needed NFT and currency', async function () {

                const nftAddress = nftmock.address;

                const currencyAddress = currency.address;
                const quantityNFTs = 1;
                const reqCurrency = 5;

                const data = abiCoder.encode(
                    ['address', 'uint256', 'address', 'uint256'],
                    [nftAddress, quantityNFTs, currencyAddress, reqCurrency]);


                await nftmock.connect(userTwo).mint();

                await currency.connect(userTwo).mint(userTwoAddress, 5);


                await expect(
                    lensHub.setFollowModule(FIRST_PROFILE_ID, requiredCurrencyNFTFollowModule.address, data)
                ).to.not.be.reverted;

                await expect(
                    lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])
                ).to.not.be.reverted;

            });
        });
    });
});
