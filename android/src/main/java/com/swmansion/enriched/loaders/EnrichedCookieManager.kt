package com.swmansion.enriched.loaders

import java.net.URI
import java.util.concurrent.ConcurrentHashMap

object EnrichedCookieManager {
  private val store =
    ConcurrentHashMap<String, ConcurrentHashMap<String, String>>()

  data class Cookie(
    val domain: String,
    val name: String,
    val value: String,
  )

  fun clear() = store.clear()

  fun setCookies(cookies: List<Cookie>) {
    store.clear()

    cookies.forEach { cookie ->
      val domainMap =
        store.getOrPut(cookie.domain) { ConcurrentHashMap() }
      domainMap[cookie.name] = cookie.value
    }
  }

  fun cookieHeaderForUrl(url: String): String? {
    val host =
      try {
        URI(url).host
      } catch (e: Exception) {
        null
      } ?: return null

    val parts = mutableListOf<String>()

    store.forEach { (domain, cookies) ->
      if (domainMatches(domain, host)) {
        cookies.forEach { (name, value) ->
          parts += "$name=$value"
        }
      }
    }

    return if (parts.isNotEmpty()) parts.joinToString("; ") else null
  }

  private fun domainMatches(
    cookieDomain: String,
    host: String,
  ): Boolean =
    host == cookieDomain ||
      (cookieDomain.startsWith(".") && host.endsWith(cookieDomain))
}
