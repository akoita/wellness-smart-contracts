// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Challenge, ChallengeCompletion } from "../types/DataTypes.sol";

/// @title IterableMapping
/// @dev Library for managing iterable mappings of challenges and challenge completions
library IterableMapping {
    // Type declarations

    /// @dev Iterable mapping for challenges
    struct ChallengesItMap {
        mapping(uint256 => Challenge) _values;
        uint256[] _keys;
    }

    /// @dev Iterable mapping for challenge completions
    struct ChallengeCompletionsItMap {
        mapping(uint256 => ChallengeCompletion) _values;
        uint256[] _keys;
    }

    // Internal functions for ChallengesItMap

    /// @notice Sets a challenge in the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @param key The key for the challenge
    /// @param value The challenge to set
    /// @return replaced True if the challenge was replaced, false otherwise
    function set(ChallengesItMap storage self, uint256 key, Challenge memory value) internal returns (bool replaced) {
        if (self._values[key].id != 0) {
            replaced = true;
        }
        self._values[key] = value;
        self._keys.push(key);
    }

    /// @notice Removes a challenge from the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @param key The key for the challenge to remove
    /// @return success True if the challenge was removed, false otherwise
    function remove(ChallengesItMap storage self, uint256 key) internal returns (bool success) {
        if (self._values[key].id == 0) {
            return false;
        }
        delete self._values[key];
        delete self._keys[key];
        if (self._keys.length > 1) {
            self._keys[key] = self._keys[self._keys.length - 1];
        }
        self._keys.pop();
        return true;
    }

    /// @notice Checks if a challenge exists in the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @param key The key for the challenge
    /// @return True if the challenge exists, false otherwise
    function contains(ChallengesItMap storage self, uint256 key) internal view returns (bool) {
        return self._values[key].id != 0;
    }

    /// @notice Gets a challenge from the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @param key The key for the challenge
    /// @return The challenge associated with the key
    function get(ChallengesItMap storage self, uint256 key) internal view returns (Challenge storage) {
        return self._values[key];
    }

    /// @notice Gets a challenge by index
    /// @param self The storage reference to the ChallengesItMap
    /// @param index The index of the challenge
    /// @return key The key of the challenge
    /// @return value The challenge associated with the index
    function at(
        ChallengesItMap storage self,
        uint256 index
    )
        internal
        view
        returns (uint256 key, Challenge storage value)
    {
        key = self._keys[index];
        value = self._values[key];
    }

    /// @notice Gets the number of challenges in the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @return The number of challenges
    function length(ChallengesItMap storage self) internal view returns (uint256) {
        return self._keys.length;
    }

    /// @notice Gets all challenges in the mapping
    /// @param self The storage reference to the ChallengesItMap
    /// @return result An array of all challenges
    function values(ChallengesItMap storage self) internal view returns (Challenge[] memory result) {
        result = new Challenge[](self._keys.length);
        for (uint256 i = 0; i < self._keys.length; i++) {
            result[i] = self._values[self._keys[i]];
        }
        return result;
    }

    // Internal functions for ChallengeCompletionsItMap

    /// @notice Sets a challenge completion in the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @param key The key for the challenge completion
    /// @param value The challenge completion to set
    /// @return replaced True if the challenge completion was replaced, false otherwise
    function set(
        ChallengeCompletionsItMap storage self,
        uint256 key,
        ChallengeCompletion memory value
    )
        internal
        returns (bool replaced)
    {
        if (self._values[key].id != 0) {
            replaced = true;
        }
        self._values[key] = value;
        self._keys.push(key);
    }

    /// @notice Removes a challenge completion from the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @param key The key for the challenge completion to remove
    /// @return success True if the challenge completion was removed, false otherwise
    function remove(ChallengeCompletionsItMap storage self, uint256 key) internal returns (bool success) {
        if (self._values[key].id == 0) {
            return false;
        }
        delete self._values[key];
        delete self._keys[key];
        if (self._keys.length > 1) {
            self._keys[key] = self._keys[self._keys.length - 1];
        }
        self._keys.pop();
        return true;
    }

    /// @notice Checks if a challenge completion exists in the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @param key The key for the challenge completion
    /// @return True if the challenge completion exists, false otherwise
    function contains(ChallengeCompletionsItMap storage self, uint256 key) internal view returns (bool) {
        return self._values[key].id != 0;
    }

    /// @notice Gets a challenge completion from the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @param key The key for the challenge completion
    /// @return The challenge completion associated with the key
    function get(
        ChallengeCompletionsItMap storage self,
        uint256 key
    )
        internal
        view
        returns (ChallengeCompletion storage)
    {
        return self._values[key];
    }

    /// @notice Gets a challenge completion by index
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @param index The index of the challenge completion
    /// @return key The key of the challenge completion
    /// @return value The challenge completion associated with the index
    function at(
        ChallengeCompletionsItMap storage self,
        uint256 index
    )
        internal
        view
        returns (uint256 key, ChallengeCompletion storage value)
    {
        key = self._keys[index];
        value = self._values[key];
    }

    /// @notice Gets the number of challenge completions in the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @return The number of challenge completions
    function length(ChallengeCompletionsItMap storage self) internal view returns (uint256) {
        return self._keys.length;
    }

    /// @notice Gets all challenge completions in the mapping
    /// @param self The storage reference to the ChallengeCompletionsItMap
    /// @return result An array of all challenge completions
    function values(ChallengeCompletionsItMap storage self)
        internal
        view
        returns (ChallengeCompletion[] memory result)
    {
        result = new ChallengeCompletion[](self._keys.length);
        for (uint256 i = 0; i < self._keys.length; i++) {
            result[i] = self._values[self._keys[i]];
        }
        return result;
    }
}
