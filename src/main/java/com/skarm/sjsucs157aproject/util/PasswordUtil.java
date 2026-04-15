package com.skarm.sjsucs157aproject.util;

import de.mkammerer.argon2.Argon2;
import de.mkammerer.argon2.Argon2Factory;

public class PasswordUtil {

    // argon2id knobs — dont make em weaker for class demo
    private static final int ITERATIONS = 2;
    private static final int MEMORY_KIB = 19456;
    private static final int PARALLELISM = 1;

    private static final Argon2 ARGON2 = Argon2Factory.create(Argon2Factory.Argon2Types.ARGON2id);

    public static String hashPassword(String password) {
        char[] chars = password.toCharArray();
        try {
            return ARGON2.hash(ITERATIONS, MEMORY_KIB, PARALLELISM, chars);
        } finally {
            ARGON2.wipeArray(chars);
        }
    }

    public static boolean verifyPassword(String hash, String password) {
        char[] chars = password.toCharArray();
        try {
            return ARGON2.verify(hash, chars);
        } finally {
            ARGON2.wipeArray(chars);
        }
    }
}
