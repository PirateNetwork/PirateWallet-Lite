#ifndef _ZEC_PAPER_RUST_H
#define _ZEC_PAPER_RUST_H

#ifdef __cplusplus
extern "C" {
#endif

extern bool   litelib_check_server        (const char* server);
extern bool   litelib_wallet_exists       ();
extern char * litelib_initialize_new      (const char* server);
extern char * litelib_initialize_new_from_phrase
                                          (const char* server, const char* seed,
                                           unsigned long long birthday);
extern char * litelib_initialize_existing (const char* server);
extern char * litelib_execute             (const char* s, const char* args);
extern void   litelib_rust_free_string    (char* s);

#ifdef __cplusplus
}
#endif

// This is a function implemented in connection.cpp that will process a string response from
// the litelib and turn into into a QString in a memory-safe way.
QString litelib_process_response(char* resp);

#endif
