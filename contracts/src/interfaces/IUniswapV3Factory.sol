// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    function initialize(uint160 sqrtPriceX96) external;
} 