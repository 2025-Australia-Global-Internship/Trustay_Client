package com.maritel.trustay.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class AmountSplitUtilsTest {

    @Test
    void splitEvenly_distributesRemainderFromFront() {
        long[] shares = AmountSplitUtils.splitEvenly(1000, 3);

        assertArrayEquals(new long[]{334, 333, 333}, shares);
        assertEquals(1000, shares[0] + shares[1] + shares[2]);
    }

    @Test
    void splitEvenly_withZeroAmount_returnsAllZeros() {
        long[] shares = AmountSplitUtils.splitEvenly(0, 4);

        assertArrayEquals(new long[]{0, 0, 0, 0}, shares);
    }

    @Test
    void splitEvenly_withInvalidParticipantCount_throwsException() {
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> AmountSplitUtils.splitEvenly(100, 0)
        );

        assertEquals("participantCount must be >= 1", exception.getMessage());
    }

    @Test
    void splitEvenly_withNegativeAmount_throwsException() {
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> AmountSplitUtils.splitEvenly(-1, 2)
        );

        assertEquals("totalAmount must be >= 0", exception.getMessage());
    }
}
