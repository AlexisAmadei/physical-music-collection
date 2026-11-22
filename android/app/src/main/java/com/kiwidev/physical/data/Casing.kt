package com.kiwidev.physical.data

import java.util.Locale

/** Upper case independent of the device region ("vinyl" stays "VINYL" on a Turkish device). */
fun String.upperCase(): String = uppercase(Locale.ROOT)

/** Lower case independent of the device region. */
fun String.lowerCase(): String = lowercase(Locale.ROOT)
