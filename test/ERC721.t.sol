// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ERC721.sol"; 

// Extend ERC721Token to expose _mint and _burn for testing.
contract TestERC721Token is ERC721Token {
    constructor(string memory _name, string memory _symbol)
        ERC721Token(_name, _symbol)
    {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

// A mock contract that implements IERC721Receiver correctly.
contract ERC721ReceiverMock is IERC721Receiver {
    bytes4 public constant ERC721_RECEIVED = IERC721Receiver.onERC721Received.selector;

    function onERC721Received(
        address operator, 
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return ERC721_RECEIVED;
    }
}

// A dummy contract that does NOT implement IERC721Receiver.
contract NonERC721ReceiverMock {
    // No implementation.
}

contract ERC721TokenTest is Test {
    TestERC721Token token;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        token = new TestERC721Token("TestToken", "TT");
    }

    function testMint() public {
        token.mint(alice, 1);
        assertEq(token.ownerOf(1), alice);
        assertEq(token.balanceOf(alice), 1);
    }

    function testTransfer() public {
        token.mint(alice, 2);
        vm.prank(alice);
        token.transferFrom(alice, bob, 2);
        assertEq(token.ownerOf(2), bob);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 1);
    }

    function testApproveAndTransfer() public {
        token.mint(alice, 3);
        vm.prank(alice);
        token.approve(bob, 3);
        vm.prank(bob);
        token.transferFrom(alice, bob, 3);
        assertEq(token.ownerOf(3), bob);
    }

    function testSetApprovalForAll() public {
        token.mint(alice, 4);
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        vm.prank(bob);
        token.transferFrom(alice, bob, 4);
        assertEq(token.ownerOf(4), bob);
    }

    function testSafeTransfer() public {
        token.mint(alice, 5);
        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 5);
        assertEq(token.ownerOf(5), bob);
    }

    function testSafeTransferToReceiver() public {
        token.mint(alice, 6);
        ERC721ReceiverMock receiver = new ERC721ReceiverMock();
        vm.prank(alice);
        token.safeTransferFrom(alice, address(receiver), 6);
        assertEq(token.ownerOf(6), address(receiver));
    }

    function testSafeTransferToNonReceiver() public {
        token.mint(alice, 7);
        NonERC721ReceiverMock nonReceiver = new NonERC721ReceiverMock();
        vm.prank(alice);
        vm.expectRevert("Non ERC721Receiver");
        token.safeTransferFrom(alice, address(nonReceiver), 7);
    }

    function testBurn() public {
        token.mint(alice, 8);
        assertEq(token.ownerOf(8), alice);
        token.burn(8);
        vm.expectRevert("Token does not exist");
        token.ownerOf(8);
    }
}
