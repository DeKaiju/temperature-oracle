// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library QuickSort {
    function quickSort(
        int16[] memory arr,
        uint16 left,
        uint16 right
    ) private pure {
        uint16 i = left;
        uint16 j = right;
        if (i == j) return;
        int16 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function sort(int16[] memory data) public pure returns (int16[] memory) {
        quickSort(data, uint16(0), uint16(data.length - 1));
        return data;
    }
}
