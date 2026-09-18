#pragma once

#if defined(_WIN32)
#  if defined(WINAPP_SHARED_BUILD)
#    define WINAPP_API __declspec(dllexport)
#  else
#    define WINAPP_API __declspec(dllimport)
#  endif
#else
#  define WINAPP_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

WINAPP_API int winapp_add(int lhs, int rhs);

#ifdef __cplusplus
}
#endif
