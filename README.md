# Koru Dao

## Installation

Install the dependencies using `yarn`:

```console
$ yarn install
```

## Configuration

You must create a `.env` file in the root directory and set the following values
in it:

```
ALCHEMY_ID=<you alchemy API key>
PK=<the private key for the deployer address>
```

Without these, tests and deployment will not work.

## Tests

To run the tests, first **compile**, then run the tests:

```console
$ npx hardhat compile
$ npx hardhat test
```

## Contracts

- [`KoruDao.sol`](#korudaosol)
- [`KoruDaoNFT.sol`](#korudaonftsol)
- [`TimeRestrictionForPosting.sol`](#timerestrictionforpostingsol)

### `KoruDao.sol`

Main contract which holds korudao.lens handle. Koru Dao members will be able to perform actions (post/follow/mirror/...) on behalf of korudao.lens.

```ts
    function post(DataTypes.PostData calldata _postData) external onlyGelatoRelay

    function follow(uint256 _profileId, bytes calldata _followData) external onlyGelatoRelay

    function mirror(DataTypes.MirrorData calldata _mirrorData) external onlyGelatoRelay
```

- KoruDao conforms to ERC2771 standard. `post`, `follow` and `mirror` has a `onlyGelatoRelay` modifier, allowing only the `trustedForwarder` (Gelato Relay) to call these functions.

```ts
    uint256 token = restriction.checkAndUpdateRestriction(
        user,
        uint256(Action.POST)
    );
```

- Restrictions can be set for each action, limiting the frequency or exclusivity of Koru Dao members' actions.

- `checkAndUpdateRestriction` of a restriction contract is called which defines the criteria. If the Koru Dao member passes all criteria, they are allowed to perform the action.

### `KoruDaoNFT.sol`

Holder of this NFT are considered members of Koru Dao.

KoruDaoNFT is a customised openzeppelin's `ERC721EnumerableUpgradable.sol`.

```ts
abstract contract ERC721MetaTxEnumerableUpgradeable is
    ERC721EnumerableUpgradeable,
    DefaultOperatorFiltererUpgradeable

```

- Context (`msgData()` and `_msgSender()`) has been overriden to fit ERC2771 standard.

- Implements OpenSea's DefaultOperatorFilter.

```ts
    function mint()
        external
        notPaused
        onlyGelatoRelay
        onlyEligible(_msgSender())
    {
        address user = _msgSender();

        uint256 profileId = lensHub.defaultProfile(user);

        if (restricted)
            require(
                !lensProfileMinted[profileId],
                "MintRestrictions: Already minted with lens profile"
            );

        _mint(user);

        lensProfileMinted[profileId] = true;
    }
```

- `mint` also has the `onlyGelatoRelay`.

- `onlyEligible` ensures lens holder meet certain criterias to be able to mint. (Definied in `MintRestrictions.sol`)

- Each lens profile id is only able to mint once.

```ts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (to != address(0)) _onlyOnePerAccount(to);

        super._beforeTokenTransfer(from, to, tokenId);
    }
```

- Each address can only hold one KoruDaoNFT at a time.

## `TimeRestrictionForPosting.sol`

Called by KoruDao, this contract has restrictions that prevents Koru Dao members from posting too frequently.

This contract can be customised to have different restrictions and activated for different actions.

```ts
    function checkRestriction(uint256 _token, uint256 _action)
        public
        view
        override
    {
        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        require(
            (block.timestamp - lastActionTime[tokenActionHash] >=
                actionInterval),
            "TimeRestrictionForPosting: Too frequent"
        );
    }
```

- Koru Dao members can only perform actions at an interval (`actionInterval`).
