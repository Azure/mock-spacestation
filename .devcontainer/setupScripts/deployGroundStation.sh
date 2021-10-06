#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Used on a blank VM Sets up the local environment to emulate connectivity to the SpaceStation.  This is slipstreamed into the AzureVM.bicep file to be ran when the VM is provisioned
# Syntax: ./deployGroundStation.sh
export GROUNDSTATION_ROOTDIR="/groundstation"
export GROUNDSTATION_USER=""
export GROUNDSTATION_LOGS="${GROUNDSTATION_ROOTDIR}/logs"
export GROUNDSTATION_OUTBOX="${GROUNDSTATION_ROOTDIR}/toSpaceStation"
export GROUNDSTATION_INBOX="${GROUNDSTATION_ROOTDIR}/fromSpaceStation"
export GROUNDSTATION_DinD="/usr/local/bin/docker-in-docker"
export GROUNDSTATION_DinD_CONTENTSBASE64="IyEvYmluL2Jhc2gKCiMgRW5zdXJlIHRoYXQgYWxsIG5vZGVzIGluIC9kZXYvbWFwcGVyIGNvcnJlc3BvbmQgdG8gbWFwcGVkIGRldmljZXMgY3VycmVudGx5IGxvYWRlZCBieSB0aGUgZGV2aWNlLW1hcHBlciBrZXJuZWwgZHJpdmVyCmRtc2V0dXAgbWtub2RlcwoKIyBGaXJzdCwgbWFrZSBzdXJlIHRoYXQgY2dyb3VwcyBhcmUgbW91bnRlZCBjb3JyZWN0bHkuCkNHUk9VUD0vc3lzL2ZzL2Nncm91cAo6IHtMT0c6PXN0ZGlvfQoKWyAtZCAkQ0dST1VQIF0gfHwKCW1rZGlyICRDR1JPVVAKCm1vdW50cG9pbnQgLXEgJENHUk9VUCB8fAoJbW91bnQgLW4gLXQgdG1wZnMgLW8gdWlkPTAsZ2lkPTAsbW9kZT0wNzU1IGNncm91cCAkQ0dST1VQIHx8IHsKCQllY2hvICJDb3VsZCBub3QgbWFrZSBhIHRtcGZzIG1vdW50LiBEaWQgeW91IHVzZSAtLXByaXZpbGVnZWQ/IgoJCWV4aXQgMQoJfQoKaWYgWyAtZCAvc3lzL2tlcm5lbC9zZWN1cml0eSBdICYmICEgbW91bnRwb2ludCAtcSAvc3lzL2tlcm5lbC9zZWN1cml0eQp0aGVuCiAgICBtb3VudCAtdCBzZWN1cml0eWZzIG5vbmUgL3N5cy9rZXJuZWwvc2VjdXJpdHkgfHwgewogICAgICAgIGVjaG8gIkNvdWxkIG5vdCBtb3VudCAvc3lzL2tlcm5lbC9zZWN1cml0eS4iCiAgICAgICAgZWNobyAiQXBwQXJtb3IgZGV0ZWN0aW9uIGFuZCAtLXByaXZpbGVnZWQgbW9kZSBtaWdodCBicmVhay4iCiAgICB9CmZpCgojIE1vdW50IHRoZSBjZ3JvdXAgaGllcmFyY2hpZXMgZXhhY3RseSBhcyB0aGV5IGFyZSBpbiB0aGUgcGFyZW50IHN5c3RlbS4KZm9yIFNVQlNZUyBpbiAkKGN1dCAtZDogLWYyIC9wcm9jLzEvY2dyb3VwKQpkbwogICAgICAgIFsgLWQgJENHUk9VUC8kU1VCU1lTIF0gfHwgbWtkaXIgJENHUk9VUC8kU1VCU1lTCiAgICAgICAgbW91bnRwb2ludCAtcSAkQ0dST1VQLyRTVUJTWVMgfHwKICAgICAgICAgICAgICAgIG1vdW50IC1uIC10IGNncm91cCAtbyAkU1VCU1lTIGNncm91cCAkQ0dST1VQLyRTVUJTWVMKCiAgICAgICAgIyBUaGUgdHdvIGZvbGxvd2luZyBzZWN0aW9ucyBhZGRyZXNzIGEgYnVnIHdoaWNoIG1hbmlmZXN0cyBpdHNlbGYKICAgICAgICAjIGJ5IGEgY3J5cHRpYyAibHhjLXN0YXJ0OiBubyBuc19jZ3JvdXAgb3B0aW9uIHNwZWNpZmllZCIgd2hlbgogICAgICAgICMgdHJ5aW5nIHRvIHN0YXJ0IGNvbnRhaW5lcnMgd2l0aGluYSBjb250YWluZXIuCiAgICAgICAgIyBUaGUgYnVnIHNlZW1zIHRvIGFwcGVhciB3aGVuIHRoZSBjZ3JvdXAgaGllcmFyY2hpZXMgYXJlIG5vdAogICAgICAgICMgbW91bnRlZCBvbiB0aGUgZXhhY3Qgc2FtZSBkaXJlY3RvcmllcyBpbiB0aGUgaG9zdCwgYW5kIGluIHRoZQogICAgICAgICMgY29udGFpbmVyLgoKICAgICAgICAjIE5hbWVkLCBjb250cm9sLWxlc3MgY2dyb3VwcyBhcmUgbW91bnRlZCB3aXRoICItbyBuYW1lPWZvbyIKICAgICAgICAjIChhbmQgYXBwZWFyIGFzIHN1Y2ggdW5kZXIgL3Byb2MvPHBpZD4vY2dyb3VwKSBidXQgYXJlIHVzdWFsbHkKICAgICAgICAjIG1vdW50ZWQgb24gYSBkaXJlY3RvcnkgbmFtZWQgImZvbyIgKHdpdGhvdXQgdGhlICJuYW1lPSIgcHJlZml4KS4KICAgICAgICAjIFN5c3RlbWQgYW5kIE9wZW5SQyAoYW5kIHBvc3NpYmx5IG90aGVycykgYm90aCBjcmVhdGUgc3VjaCBhCiAgICAgICAgIyBjZ3JvdXAuIFRvIGF2b2lkIHRoZSBhZm9yZW1lbnRpb25lZCBidWcsIHdlIHN5bWxpbmsgImZvbyIgdG8KICAgICAgICAjICJuYW1lPWZvbyIuIFRoaXMgc2hvdWxkbid0IGhhdmUgYW55IGFkdmVyc2UgZWZmZWN0LgogICAgICAgIGVjaG8gJFNVQlNZUyB8IGdyZXAgLXEgXm5hbWU9ICYmIHsKICAgICAgICAgICAgICAgIE5BTUU9JChlY2hvICRTVUJTWVMgfCBzZWQgcy9ebmFtZT0vLykKICAgICAgICAgICAgICAgIGxuIC1zICRTVUJTWVMgJENHUk9VUC8kTkFNRQogICAgICAgIH0KCiAgICAgICAgIyBMaWtld2lzZSwgb24gYXQgbGVhc3Qgb25lIHN5c3RlbSwgaXQgaGFzIGJlZW4gcmVwb3J0ZWQgdGhhdAogICAgICAgICMgc3lzdGVtZCB3b3VsZCBtb3VudCB0aGUgQ1BVIGFuZCBDUFUgYWNjb3VudGluZyBjb250cm9sbGVycwogICAgICAgICMgKHJlc3BlY3RpdmVseSAiY3B1IiBhbmQgImNwdWFjY3QiKSB3aXRoICItbyBjcHVhY2N0LGNwdSIKICAgICAgICAjIGJ1dCBvbiBhIGRpcmVjdG9yeSBjYWxsZWQgImNwdSxjcHVhY2N0IiAobm90ZSB0aGUgaW52ZXJzaW9uCiAgICAgICAgIyBpbiB0aGUgb3JkZXIgb2YgdGhlIGdyb3VwcykuIFRoaXMgdHJpZXMgdG8gd29yayBhcm91bmQgaXQuCiAgICAgICAgWyAkU1VCU1lTID0gY3B1YWNjdCxjcHUgXSAmJiBsbiAtcyAkU1VCU1lTICRDR1JPVVAvY3B1LGNwdWFjY3QKZG9uZQoKIyBOb3RlOiBhcyBJIHdyaXRlIHRob3NlIGxpbmVzLCB0aGUgTFhDIHVzZXJsYW5kIHRvb2xzIGNhbm5vdCBzZXR1cAojIGEgInN1Yi1jb250YWluZXIiIHByb3Blcmx5IGlmIHRoZSAiZGV2aWNlcyIgY2dyb3VwIGlzIG5vdCBpbiBpdHMKIyBvd24gaGllcmFyY2h5LiBMZXQncyBkZXRlY3QgdGhpcyBhbmQgaXNzdWUgYSB3YXJuaW5nLgpncmVwIC1xIDpkZXZpY2VzOiAvcHJvYy8xL2Nncm91cCB8fAoJZWNobyAiV0FSTklORzogdGhlICdkZXZpY2VzJyBjZ3JvdXAgc2hvdWxkIGJlIGluIGl0cyBvd24gaGllcmFyY2h5LiIKZ3JlcCAtcXcgZGV2aWNlcyAvcHJvYy8xL2Nncm91cCB8fAoJZWNobyAiV0FSTklORzogaXQgbG9va3MgbGlrZSB0aGUgJ2RldmljZXMnIGNncm91cCBpcyBub3QgbW91bnRlZC4iCgojIE5vdywgY2xvc2UgZXh0cmFuZW91cyBmaWxlIGRlc2NyaXB0b3JzLgpwdXNoZCAvcHJvYy9zZWxmL2ZkID4vZGV2L251bGwKZm9yIEZEIGluICoKZG8KCWNhc2UgIiRGRCIgaW4KCSMgS2VlcCBzdGRpbi9zdGRvdXQvc3RkZXJyCglbMDEyXSkKCQk7OwoJIyBOdWtlIGV2ZXJ5dGhpbmcgZWxzZQoJKikKCQlldmFsIGV4ZWMgIiRGRD4mLSIKCQk7OwoJZXNhYwpkb25lCnBvcGQgPi9kZXYvbnVsbAoKCiMgSWYgYSBwaWRmaWxlIGlzIHN0aWxsIGFyb3VuZCAoZm9yIGV4YW1wbGUgYWZ0ZXIgYSBjb250YWluZXIgcmVzdGFydCksCiMgZGVsZXRlIGl0IHNvIHRoYXQgZG9ja2VyIGNhbiBzdGFydC4Kcm0gLXJmIC92YXIvcnVuL2RvY2tlci5waWQKCiMgSWYgd2Ugd2VyZSBnaXZlbiBhIFBPUlQgZW52aXJvbm1lbnQgdmFyaWFibGUsIHN0YXJ0IGFzIGEgc2ltcGxlIGRhZW1vbjsKIyBvdGhlcndpc2UsIHNwYXduIGEgc2hlbGwgYXMgd2VsbAppZiBbICIkUE9SVCIgXQp0aGVuCglleGVjIGRvY2tlcmQgLUggMC4wLjAuMDokUE9SVCAtSCB1bml4Oi8vL3Zhci9ydW4vZG9ja2VyLnNvY2sgXAoJCSRET0NLRVJfREFFTU9OX0FSR1MKZWxzZQoJaWYgWyAiJExPRyIgPT0gImZpbGUiIF0KCXRoZW4KCQlkb2NrZXJkICRET0NLRVJfREFFTU9OX0FSR1MgJj4vdmFyL2xvZy9kb2NrZXIubG9nICYKCWVsc2UKCQlkb2NrZXJkICRET0NLRVJfREFFTU9OX0FSR1MgJgoJZmkKCSgoIHRpbWVvdXQgPSA2MCArIFNFQ09ORFMgKSkKCXVudGlsIGRvY2tlciBpbmZvID4vZGV2L251bGwgMj4mMQoJZG8KCQlpZiAoKCBTRUNPTkRTID49IHRpbWVvdXQgKSk7IHRoZW4KCQkJZWNobyAnVGltZWQgb3V0IHRyeWluZyB0byBjb25uZWN0IHRvIGludGVybmFsIGRvY2tlciBob3N0LicgPiYyCgkJCWJyZWFrCgkJZmkKCQlzbGVlcCAxCglkb25lCgkjW1sgJDEgXV0gJiYgZXhlYyAiJEAiCgkjZXhlYyBiYXNoIC0tbG9naW4KZmk="
export SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="IyEvdXNyL2Jpbi9lbnYgYmFzaAojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBBbGwgcmlnaHRzIHJlc2VydmVkLgojIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgTGljZW5zZS4gU2VlIGh0dHBzOi8vZ28ubWljcm9zb2Z0LmNvbS9md2xpbmsvP2xpbmtpZD0yMDkwMzE2IGZvciBsaWNlbnNlIGluZm9ybWF0aW9uLgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojCiMgRG9jczogaHR0cHM6Ly9naXRodWIuY29tL21pY3Jvc29mdC92c2NvZGUtZGV2LWNvbnRhaW5lcnMvYmxvYi9tYWluL3NjcmlwdC1saWJyYXJ5L2RvY3MvZG9ja2VyLm1kCiMgTWFpbnRhaW5lcjogVGhlIFZTIENvZGUgYW5kIENvZGVzcGFjZXMgVGVhbXMKIwojIFN5bnRheDogLi9kb2NrZXItZGViaWFuLnNoIFtlbmFibGUgbm9uLXJvb3QgZG9ja2VyIHNvY2tldCBhY2Nlc3MgZmxhZ10gW3NvdXJjZSBzb2NrZXRdIFt0YXJnZXQgc29ja2V0XSBbbm9uLXJvb3QgdXNlcl0gW3VzZSBtb2J5XQoKRU5BQkxFX05PTlJPT1RfRE9DS0VSPSR7MTotInRydWUifQpTT1VSQ0VfU09DS0VUPSR7MjotIi92YXIvcnVuL2RvY2tlci1ob3N0LnNvY2sifQpUQVJHRVRfU09DS0VUPSR7MzotIi92YXIvcnVuL2RvY2tlci5zb2NrIn0KVVNFUk5BTUU9JHs0Oi0iYXV0b21hdGljIn0KVVNFX01PQlk9JHs1Oi0idHJ1ZSJ9Ck1JQ1JPU09GVF9HUEdfS0VZU19VUkk9Imh0dHBzOi8vcGFja2FnZXMubWljcm9zb2Z0LmNvbS9rZXlzL21pY3Jvc29mdC5hc2MiCkRPQ0tFUl9EQVNIX0NPTVBPU0VfVkVSU0lPTj0iMSIKCnNldCAtZQoKaWYgWyAiJChpZCAtdSkiIC1uZSAwIF07IHRoZW4KICAgIGVjaG8gLWUgJ1NjcmlwdCBtdXN0IGJlIHJ1biBhcyByb290LiBVc2Ugc3Vkbywgc3UsIG9yIGFkZCAiVVNFUiByb290IiB0byB5b3VyIERvY2tlcmZpbGUgYmVmb3JlIHJ1bm5pbmcgdGhpcyBzY3JpcHQuJwogICAgZXhpdCAxCmZpCgojIERldGVybWluZSB0aGUgYXBwcm9wcmlhdGUgbm9uLXJvb3QgdXNlcgppZiBbICIke1VTRVJOQU1FfSIgPSAiYXV0byIgXSB8fCBbICIke1VTRVJOQU1FfSIgPSAiYXV0b21hdGljIiBdOyB0aGVuCiAgICBVU0VSTkFNRT0iIgogICAgUE9TU0lCTEVfVVNFUlM9KCJ2c2NvZGUiICJub2RlIiAiY29kZXNwYWNlIiAiJChhd2sgLXYgdmFsPTEwMDAgLUYgIjoiICckMz09dmFse3ByaW50ICQxfScgL2V0Yy9wYXNzd2QpIikKICAgIGZvciBDVVJSRU5UX1VTRVIgaW4gJHtQT1NTSUJMRV9VU0VSU1tAXX07IGRvCiAgICAgICAgaWYgaWQgLXUgJHtDVVJSRU5UX1VTRVJ9ID4gL2Rldi9udWxsIDI+JjE7IHRoZW4KICAgICAgICAgICAgVVNFUk5BTUU9JHtDVVJSRU5UX1VTRVJ9CiAgICAgICAgICAgIGJyZWFrCiAgICAgICAgZmkKICAgIGRvbmUKICAgIGlmIFsgIiR7VVNFUk5BTUV9IiA9ICIiIF07IHRoZW4KICAgICAgICBVU0VSTkFNRT1yb290CiAgICBmaQplbGlmIFsgIiR7VVNFUk5BTUV9IiA9ICJub25lIiBdIHx8ICEgaWQgLXUgJHtVU0VSTkFNRX0gPiAvZGV2L251bGwgMj4mMTsgdGhlbgogICAgVVNFUk5BTUU9cm9vdApmaQoKIyBHZXQgY2VudHJhbCBjb21tb24gc2V0dGluZwpnZXRfY29tbW9uX3NldHRpbmcoKSB7CiAgICBpZiBbICIke2NvbW1vbl9zZXR0aW5nc19maWxlX2xvYWRlZH0iICE9ICJ0cnVlIiBdOyB0aGVuCiAgICAgICAgY3VybCAtc2ZMICJodHRwczovL2FrYS5tcy92c2NvZGUtZGV2LWNvbnRhaW5lcnMvc2NyaXB0LWxpYnJhcnkvc2V0dGluZ3MuZW52IiAyPi9kZXYvbnVsbCAtbyAvdG1wL3ZzZGMtc2V0dGluZ3MuZW52IHx8IGVjaG8gIkNvdWxkIG5vdCBkb3dubG9hZCBzZXR0aW5ncyBmaWxlLiBTa2lwcGluZy4iCiAgICAgICAgY29tbW9uX3NldHRpbmdzX2ZpbGVfbG9hZGVkPXRydWUKICAgIGZpCiAgICBpZiBbIC1mICIvdG1wL3ZzZGMtc2V0dGluZ3MuZW52IiBdOyB0aGVuCiAgICAgICAgbG9jYWwgbXVsdGlfbGluZT0iIgogICAgICAgIGlmIFsgIiQyIiA9ICJ0cnVlIiBdOyB0aGVuIG11bHRpX2xpbmU9Ii16IjsgZmkKICAgICAgICBsb2NhbCByZXN1bHQ9IiQoZ3JlcCAke211bHRpX2xpbmV9IC1vUCAiJDE9XCI/XEtbXlwiXSsiIC90bXAvdnNkYy1zZXR0aW5ncy5lbnYgfCB0ciAtZCAnXDAnKSIKICAgICAgICBpZiBbICEgLXogIiR7cmVzdWx0fSIgXTsgdGhlbiBkZWNsYXJlIC1nICQxPSIke3Jlc3VsdH0iOyBmaQogICAgZmkKICAgIGVjaG8gIiQxPSR7ITF9Igp9CgojIEZ1bmN0aW9uIHRvIHJ1biBhcHQtZ2V0IGlmIG5lZWRlZAphcHRfZ2V0X3VwZGF0ZV9pZl9uZWVkZWQoKQp7CiAgICBpZiBbICEgLWQgIi92YXIvbGliL2FwdC9saXN0cyIgXSB8fCBbICIkKGxzIC92YXIvbGliL2FwdC9saXN0cy8gfCB3YyAtbCkiID0gIjAiIF07IHRoZW4KICAgICAgICBlY2hvICJSdW5uaW5nIGFwdC1nZXQgdXBkYXRlLi4uIgogICAgICAgIGFwdC1nZXQgdXBkYXRlCiAgICBlbHNlCiAgICAgICAgZWNobyAiU2tpcHBpbmcgYXB0LWdldCB1cGRhdGUuIgogICAgZmkKfQoKIyBDaGVja3MgaWYgcGFja2FnZXMgYXJlIGluc3RhbGxlZCBhbmQgaW5zdGFsbHMgdGhlbSBpZiBub3QKY2hlY2tfcGFja2FnZXMoKSB7CiAgICBpZiAhIGRwa2cgLXMgIiRAIiA+IC9kZXYvbnVsbCAyPiYxOyB0aGVuCiAgICAgICAgYXB0X2dldF91cGRhdGVfaWZfbmVlZGVkCiAgICAgICAgYXB0LWdldCAteSBpbnN0YWxsIC0tbm8taW5zdGFsbC1yZWNvbW1lbmRzICIkQCIKICAgIGZpCn0KCiMgRmlndXJlIG91dCBjb3JyZWN0IHZlcnNpb24gb2YgYSB0aHJlZSBwYXJ0IHZlcnNpb24gbnVtYmVyIGlzIG5vdCBwYXNzZWQKZmluZF92ZXJzaW9uX2Zyb21fZ2l0X3RhZ3MoKSB7CiAgICBsb2NhbCB2YXJpYWJsZV9uYW1lPSQxCiAgICBsb2NhbCByZXF1ZXN0ZWRfdmVyc2lvbj0keyF2YXJpYWJsZV9uYW1lfQogICAgaWYgWyAiJHtyZXF1ZXN0ZWRfdmVyc2lvbn0iID0gIm5vbmUiIF07IHRoZW4gcmV0dXJuOyBmaQogICAgbG9jYWwgcmVwb3NpdG9yeT0kMgogICAgbG9jYWwgcHJlZml4PSR7MzotInRhZ3MvdiJ9CiAgICBsb2NhbCBzZXBhcmF0b3I9JHs0Oi0iLiJ9CiAgICBsb2NhbCBsYXN0X3BhcnRfb3B0aW9uYWw9JHs1Oi0iZmFsc2UifQogICAgaWYgWyAiJChlY2hvICIke3JlcXVlc3RlZF92ZXJzaW9ufSIgfCBncmVwIC1vICIuIiB8IHdjIC1sKSIgIT0gIjIiIF07IHRoZW4KICAgICAgICBsb2NhbCBlc2NhcGVkX3NlcGFyYXRvcj0ke3NlcGFyYXRvci8vLi9cXC59CiAgICAgICAgbG9jYWwgbGFzdF9wYXJ0CiAgICAgICAgaWYgWyAiJHtsYXN0X3BhcnRfb3B0aW9uYWx9IiA9ICJ0cnVlIiBdOyB0aGVuCiAgICAgICAgICAgIGxhc3RfcGFydD0iKCR7ZXNjYXBlZF9zZXBhcmF0b3J9WzAtOV0rKT8iCiAgICAgICAgZWxzZQogICAgICAgICAgICBsYXN0X3BhcnQ9IiR7ZXNjYXBlZF9zZXBhcmF0b3J9WzAtOV0rIgogICAgICAgIGZpCiAgICAgICAgbG9jYWwgcmVnZXg9IiR7cHJlZml4fVxcS1swLTldKyR7ZXNjYXBlZF9zZXBhcmF0b3J9WzAtOV0rJHtsYXN0X3BhcnR9JCIKICAgICAgICBsb2NhbCB2ZXJzaW9uX2xpc3Q9IiQoZ2l0IGxzLXJlbW90ZSAtLXRhZ3MgJHtyZXBvc2l0b3J5fSB8IGdyZXAgLW9QICIke3JlZ2V4fSIgfCB0ciAtZCAnICcgfCB0ciAiJHtzZXBhcmF0b3J9IiAiLiIgfCBzb3J0IC1yVikiCiAgICAgICAgaWYgWyAiJHtyZXF1ZXN0ZWRfdmVyc2lvbn0iID0gImxhdGVzdCIgXSB8fCBbICIke3JlcXVlc3RlZF92ZXJzaW9ufSIgPSAiY3VycmVudCIgXSB8fCBbICIke3JlcXVlc3RlZF92ZXJzaW9ufSIgPSAibHRzIiBdOyB0aGVuCiAgICAgICAgICAgIGRlY2xhcmUgLWcgJHt2YXJpYWJsZV9uYW1lfT0iJChlY2hvICIke3ZlcnNpb25fbGlzdH0iIHwgaGVhZCAtbiAxKSIKICAgICAgICBlbHNlCiAgICAgICAgICAgIHNldCArZQogICAgICAgICAgICBkZWNsYXJlIC1nICR7dmFyaWFibGVfbmFtZX09IiQoZWNobyAiJHt2ZXJzaW9uX2xpc3R9IiB8IGdyZXAgLUUgLW0gMSAiXiR7cmVxdWVzdGVkX3ZlcnNpb24vLy4vXFwufShbXFwuXFxzXXwkKSIpIgogICAgICAgICAgICBzZXQgLWUKICAgICAgICBmaQogICAgZmkKICAgIGlmIFsgLXogIiR7IXZhcmlhYmxlX25hbWV9IiBdIHx8ICEgZWNobyAiJHt2ZXJzaW9uX2xpc3R9IiB8IGdyZXAgIl4keyF2YXJpYWJsZV9uYW1lLy8uL1xcLn0kIiA+IC9kZXYvbnVsbCAyPiYxOyB0aGVuCiAgICAgICAgZWNobyAtZSAiSW52YWxpZCAke3ZhcmlhYmxlX25hbWV9IHZhbHVlOiAke3JlcXVlc3RlZF92ZXJzaW9ufVxuVmFsaWQgdmFsdWVzOlxuJHt2ZXJzaW9uX2xpc3R9IiA+JjIKICAgICAgICBleGl0IDEKICAgIGZpCiAgICBlY2hvICIke3ZhcmlhYmxlX25hbWV9PSR7IXZhcmlhYmxlX25hbWV9Igp9CgojIEVuc3VyZSBhcHQgaXMgaW4gbm9uLWludGVyYWN0aXZlIHRvIGF2b2lkIHByb21wdHMKZXhwb3J0IERFQklBTl9GUk9OVEVORD1ub25pbnRlcmFjdGl2ZQoKIyBJbnN0YWxsIGRlcGVuZGVuY2llcwpjaGVja19wYWNrYWdlcyBhcHQtdHJhbnNwb3J0LWh0dHBzIGN1cmwgY2EtY2VydGlmaWNhdGVzIGdudXBnMiBkaXJtbmdyCmlmICEgdHlwZSBnaXQgPiAvZGV2L251bGwgMj4mMTsgdGhlbgogICAgYXB0X2dldF91cGRhdGVfaWZfbmVlZGVkCiAgICBhcHQtZ2V0IC15IGluc3RhbGwgZ2l0CmZpCgojIEluc3RhbGwgRG9ja2VyIC8gTW9ieSBDTEkgaWYgbm90IGFscmVhZHkgaW5zdGFsbGVkCmFyY2hpdGVjdHVyZT0iJChkcGtnIC0tcHJpbnQtYXJjaGl0ZWN0dXJlKSIKaWYgdHlwZSBkb2NrZXIgPiAvZGV2L251bGwgMj4mMTsgdGhlbgogICAgZWNobyAiRG9ja2VyIC8gTW9ieSBDTEkgYWxyZWFkeSBpbnN0YWxsZWQuIgplbHNlCiAgICAjIFNvdXJjZSAvZXRjL29zLXJlbGVhc2UgdG8gZ2V0IE9TIGluZm8KICAgIC4gL2V0Yy9vcy1yZWxlYXNlCiAgICBpZiBbICIke1VTRV9NT0JZfSIgPSAidHJ1ZSIgXTsgdGhlbgogICAgICAgICMgSW1wb3J0IGtleSBzYWZlbHkgKG5ldyAnc2lnbmVkLWJ5JyBtZXRob2QgcmF0aGVyIHRoYW4gZGVwcmVjYXRlZCBhcHQta2V5IGFwcHJvYWNoKSBhbmQgaW5zdGFsbAogICAgICAgIGdldF9jb21tb25fc2V0dGluZyBNSUNST1NPRlRfR1BHX0tFWVNfVVJJCiAgICAgICAgY3VybCAtc1NMICR7TUlDUk9TT0ZUX0dQR19LRVlTX1VSSX0gfCBncGcgLS1kZWFybW9yID4gL3Vzci9zaGFyZS9rZXlyaW5ncy9taWNyb3NvZnQtYXJjaGl2ZS1rZXlyaW5nLmdwZwogICAgICAgIGVjaG8gImRlYiBbYXJjaD0ke2FyY2hpdGVjdHVyZX0gc2lnbmVkLWJ5PS91c3Ivc2hhcmUva2V5cmluZ3MvbWljcm9zb2Z0LWFyY2hpdmUta2V5cmluZy5ncGddIGh0dHBzOi8vcGFja2FnZXMubWljcm9zb2Z0LmNvbS9yZXBvcy9taWNyb3NvZnQtJHtJRH0tJHtWRVJTSU9OX0NPREVOQU1FfS1wcm9kICR7VkVSU0lPTl9DT0RFTkFNRX0gbWFpbiIgPiAvZXRjL2FwdC9zb3VyY2VzLmxpc3QuZC9taWNyb3NvZnQubGlzdAogICAgICAgIGFwdC1nZXQgdXBkYXRlCiAgICAgICAgYXB0LWdldCAteSBpbnN0YWxsIC0tbm8taW5zdGFsbC1yZWNvbW1lbmRzIG1vYnktY2xpIG1vYnktYnVpbGR4IG1vYnktZW5naW5lCiAgICAgICAgYXB0LWdldCAteSBpbnN0YWxsIC0tbm8taW5zdGFsbC1yZWNvbW1lbmRzIG1vYnktY29tcG9zZSB8fCBlY2hvICIoKikgUGFja2FnZSBtb2J5LWNvbXBvc2UgKERvY2tlciBDb21wb3NlIHYyKSBub3QgYXZhaWxhYmxlIGZvciAke1ZFUlNJT05fQ09ERU5BTUV9ICR7YXJjaGl0ZWN0dXJlfS4gU2tpcHBpbmcuIgogICAgZWxzZQogICAgICAgICMgSW1wb3J0IGtleSBzYWZlbHkgKG5ldyAnc2lnbmVkLWJ5JyBtZXRob2QgcmF0aGVyIHRoYW4gZGVwcmVjYXRlZCBhcHQta2V5IGFwcHJvYWNoKSBhbmQgaW5zdGFsbAogICAgICAgIGN1cmwgLWZzU0wgaHR0cHM6Ly9kb3dubG9hZC5kb2NrZXIuY29tL2xpbnV4LyR7SUR9L2dwZyB8IGdwZyAtLWRlYXJtb3IgPiAvdXNyL3NoYXJlL2tleXJpbmdzL2RvY2tlci1hcmNoaXZlLWtleXJpbmcuZ3BnCiAgICAgICAgZWNobyAiZGViIFthcmNoPSQoZHBrZyAtLXByaW50LWFyY2hpdGVjdHVyZSkgc2lnbmVkLWJ5PS91c3Ivc2hhcmUva2V5cmluZ3MvZG9ja2VyLWFyY2hpdmUta2V5cmluZy5ncGddIGh0dHBzOi8vZG93bmxvYWQuZG9ja2VyLmNvbS9saW51eC8ke0lEfSAke1ZFUlNJT05fQ09ERU5BTUV9IHN0YWJsZSIgPiAvZXRjL2FwdC9zb3VyY2VzLmxpc3QuZC9kb2NrZXIubGlzdAogICAgICAgIGFwdC1nZXQgdXBkYXRlCiAgICAgICAgYXB0LWdldCAteSBpbnN0YWxsIC0tbm8taW5zdGFsbC1yZWNvbW1lbmRzIGRvY2tlci1jZS1jbGkKICAgIGZpCmZpCgojIEluc3RhbGwgRG9ja2VyIENvbXBvc2UgaWYgbm90IGFscmVhZHkgaW5zdGFsbGVkICBhbmQgaXMgb24gYSBzdXBwb3J0ZWQgYXJjaGl0ZWN0dXJlCmlmIHR5cGUgZG9ja2VyLWNvbXBvc2UgPiAvZGV2L251bGwgMj4mMTsgdGhlbgogICAgZWNobyAiRG9ja2VyIENvbXBvc2UgYWxyZWFkeSBpbnN0YWxsZWQuIgplbHNlCiAgICBUQVJHRVRfQ09NUE9TRV9BUkNIPSIkKHVuYW1lIC1tKSIKICAgIGlmIFsgIiR7VEFSR0VUX0NPTVBPU0VfQVJDSH0iID0gImFtZDY0IiBdOyB0aGVuCiAgICAgICAgVEFSR0VUX0NPTVBPU0VfQVJDSD0ieDg2XzY0IgogICAgZmkKICAgIGlmIFsgIiR7VEFSR0VUX0NPTVBPU0VfQVJDSH0iICE9ICJ4ODZfNjQiIF07IHRoZW4KICAgICAgICAjIFVzZSBwaXAgdG8gZ2V0IGEgdmVyc2lvbiB0aGF0IHJ1bm5zIG9uIHRoaXMgYXJjaGl0ZWN0dXJlCiAgICAgICAgaWYgISBkcGtnIC1zIHB5dGhvbjMtbWluaW1hbCBweXRob24zLXBpcCBsaWJmZmktZGV2IHB5dGhvbjMtdmVudiA+IC9kZXYvbnVsbCAyPiYxOyB0aGVuCiAgICAgICAgICAgIGFwdF9nZXRfdXBkYXRlX2lmX25lZWRlZAogICAgICAgICAgICBhcHQtZ2V0IC15IGluc3RhbGwgcHl0aG9uMy1taW5pbWFsIHB5dGhvbjMtcGlwIGxpYmZmaS1kZXYgcHl0aG9uMy12ZW52CiAgICAgICAgZmkKICAgICAgICBleHBvcnQgUElQWF9IT01FPS91c3IvbG9jYWwvcGlweAogICAgICAgIG1rZGlyIC1wICR7UElQWF9IT01FfQogICAgICAgIGV4cG9ydCBQSVBYX0JJTl9ESVI9L3Vzci9sb2NhbC9iaW4KICAgICAgICBleHBvcnQgUFlUSE9OVVNFUkJBU0U9L3RtcC9waXAtdG1wCiAgICAgICAgZXhwb3J0IFBJUF9DQUNIRV9ESVI9L3RtcC9waXAtdG1wL2NhY2hlCiAgICAgICAgcGlweF9iaW49cGlweAogICAgICAgIGlmICEgdHlwZSBwaXB4ID4gL2Rldi9udWxsIDI+JjE7IHRoZW4KICAgICAgICAgICAgcGlwMyBpbnN0YWxsIC0tZGlzYWJsZS1waXAtdmVyc2lvbi1jaGVjayAtLW5vLXdhcm4tc2NyaXB0LWxvY2F0aW9uICAtLW5vLWNhY2hlLWRpciAtLXVzZXIgcGlweAogICAgICAgICAgICBwaXB4X2Jpbj0vdG1wL3BpcC10bXAvYmluL3BpcHgKICAgICAgICBmaQogICAgICAgICR7cGlweF9iaW59IGluc3RhbGwgLS1zeXN0ZW0tc2l0ZS1wYWNrYWdlcyAtLXBpcC1hcmdzICctLW5vLWNhY2hlLWRpciAtLWZvcmNlLXJlaW5zdGFsbCcgZG9ja2VyLWNvbXBvc2UKICAgICAgICBybSAtcmYgL3RtcC9waXAtdG1wCiAgICBlbHNlCiAgICAgICAgZmluZF92ZXJzaW9uX2Zyb21fZ2l0X3RhZ3MgRE9DS0VSX0RBU0hfQ09NUE9TRV9WRVJTSU9OICJodHRwczovL2dpdGh1Yi5jb20vZG9ja2VyL2NvbXBvc2UiICJ0YWdzLyIKICAgICAgICBlY2hvICIoKikgSW5zdGFsbGluZyBkb2NrZXItY29tcG9zZSAke0RPQ0tFUl9EQVNIX0NPTVBPU0VfVkVSU0lPTn0uLi4iCiAgICAgICAgY3VybCAtZnNTTCAiaHR0cHM6Ly9naXRodWIuY29tL2RvY2tlci9jb21wb3NlL3JlbGVhc2VzL2Rvd25sb2FkLyR7RE9DS0VSX0RBU0hfQ09NUE9TRV9WRVJTSU9OfS9kb2NrZXItY29tcG9zZS1MaW51eC14ODZfNjQiIC1vIC91c3IvbG9jYWwvYmluL2RvY2tlci1jb21wb3NlCiAgICAgICAgY2htb2QgK3ggL3Vzci9sb2NhbC9iaW4vZG9ja2VyLWNvbXBvc2UKICAgIGZpCmZpCgojIElmIGluaXQgZmlsZSBhbHJlYWR5IGV4aXN0cywgZXhpdAppZiBbIC1mICIvdXNyL2xvY2FsL3NoYXJlL2RvY2tlci1pbml0LnNoIiBdOyB0aGVuCiAgICBleGl0IDAKZmkKZWNobyAiZG9ja2VyLWluaXQgZG9lc250IGV4aXN0LCBhZGRpbmcuLi4iCgojIEJ5IGRlZmF1bHQsIG1ha2UgdGhlIHNvdXJjZSBhbmQgdGFyZ2V0IHNvY2tldHMgdGhlIHNhbWUKaWYgWyAiJHtTT1VSQ0VfU09DS0VUfSIgIT0gIiR7VEFSR0VUX1NPQ0tFVH0iIF07IHRoZW4KICAgIHRvdWNoICIke1NPVVJDRV9TT0NLRVR9IgogICAgbG4gLXMgIiR7U09VUkNFX1NPQ0tFVH0iICIke1RBUkdFVF9TT0NLRVR9IgpmaQoKIyBBZGQgYSBzdHViIGlmIG5vdCBhZGRpbmcgbm9uLXJvb3QgdXNlciBhY2Nlc3MsIHVzZXIgaXMgcm9vdAppZiBbICIke0VOQUJMRV9OT05ST09UX0RPQ0tFUn0iID0gImZhbHNlIiBdIHx8IFsgIiR7VVNFUk5BTUV9IiA9ICJyb290IiBdOyB0aGVuCiAgICBlY2hvICcvdXNyL2Jpbi9lbnYgYmFzaCAtYyAiXCRAIicgPiAvdXNyL2xvY2FsL3NoYXJlL2RvY2tlci1pbml0LnNoCiAgICBjaG1vZCAreCAvdXNyL2xvY2FsL3NoYXJlL2RvY2tlci1pbml0LnNoCiAgICBleGl0IDAKZmkKCiMgSWYgZW5hYmxpbmcgbm9uLXJvb3QgYWNjZXNzIGFuZCBzcGVjaWZpZWQgdXNlciBpcyBmb3VuZCwgc2V0dXAgc29jYXQgYW5kIGFkZCBzY3JpcHQKY2hvd24gLWggIiR7VVNFUk5BTUV9Ijpyb290ICIke1RBUkdFVF9TT0NLRVR9IgppZiAhIGRwa2cgLXMgc29jYXQgPiAvZGV2L251bGwgMj4mMTsgdGhlbgogICAgYXB0X2dldF91cGRhdGVfaWZfbmVlZGVkCiAgICBhcHQtZ2V0IC15IGluc3RhbGwgc29jYXQKZmkKdGVlIC91c3IvbG9jYWwvc2hhcmUvZG9ja2VyLWluaXQuc2ggPiAvZGV2L251bGwgXAo8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaAojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBBbGwgcmlnaHRzIHJlc2VydmVkLgojIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgTGljZW5zZS4gU2VlIGh0dHBzOi8vZ28ubWljcm9zb2Z0LmNvbS9md2xpbmsvP2xpbmtpZD0yMDkwMzE2IGZvciBsaWNlbnNlIGluZm9ybWF0aW9uLgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKc2V0IC1lCgpTT0NBVF9QQVRIX0JBU0U9L3RtcC92c2NyLWRvY2tlci1mcm9tLWRvY2tlcgpTT0NBVF9MT0c9XCR7U09DQVRfUEFUSF9CQVNFfS5sb2cKU09DQVRfUElEPVwke1NPQ0FUX1BBVEhfQkFTRX0ucGlkCgojIFdyYXBwZXIgZnVuY3Rpb24gdG8gb25seSB1c2Ugc3VkbyBpZiBub3QgYWxyZWFkeSByb290CnN1ZG9JZigpCnsKICAgIGlmIFsgIlwkKGlkIC11KSIgLW5lIDAgXTsgdGhlbgogICAgICAgIHN1ZG8gIlwkQCIKICAgIGVsc2UKICAgICAgICAiXCRAIgogICAgZmkKfQoKIyBMb2cgbWVzc2FnZXMKbG9nKCkKewogICAgZWNobyAtZSAiW1wkKGRhdGUpXSBcJEAiIHwgc3Vkb0lmIHRlZSAtYSBcJHtTT0NBVF9MT0d9ID4gL2Rldi9udWxsCn0KCmVjaG8gLWUgIlxuKiogXCQoZGF0ZSkgKioiIHwgc3Vkb0lmIHRlZSAtYSBcJHtTT0NBVF9MT0d9ID4gL2Rldi9udWxsCmxvZyAiRW5zdXJpbmcgJHtVU0VSTkFNRX0gaGFzIGFjY2VzcyB0byAke1NPVVJDRV9TT0NLRVR9IHZpYSAke1RBUkdFVF9TT0NLRVR9IgoKIyBJZiBlbmFibGVkLCB0cnkgdG8gYWRkIGEgZG9ja2VyIGdyb3VwIHdpdGggdGhlIHJpZ2h0IEdJRC4gSWYgdGhlIGdyb3VwIGlzIHJvb3QsCiMgZmFsbCBiYWNrIG9uIHVzaW5nIHNvY2F0IHRvIGZvcndhcmQgdGhlIGRvY2tlciBzb2NrZXQgdG8gYW5vdGhlciB1bml4IHNvY2tldCBzbwojIHRoYXQgd2UgY2FuIHNldCBwZXJtaXNzaW9ucyBvbiBpdCB3aXRob3V0IGFmZmVjdGluZyB0aGUgaG9zdC4KaWYgWyAiJHtFTkFCTEVfTk9OUk9PVF9ET0NLRVJ9IiA9ICJ0cnVlIiBdICYmIFsgIiR7U09VUkNFX1NPQ0tFVH0iICE9ICIke1RBUkdFVF9TT0NLRVR9IiBdICYmIFsgIiR7VVNFUk5BTUV9IiAhPSAicm9vdCIgXSAmJiBbICIke1VTRVJOQU1FfSIgIT0gIjAiIF07IHRoZW4KICAgIFNPQ0tFVF9HSUQ9XCQoc3RhdCAtYyAnJWcnICR7U09VUkNFX1NPQ0tFVH0pCiAgICBpZiBbICJcJHtTT0NLRVRfR0lEfSIgIT0gIjAiIF07IHRoZW4KICAgICAgICBsb2cgIkFkZGluZyB1c2VyIHRvIGdyb3VwIHdpdGggR0lEIFwke1NPQ0tFVF9HSUR9LiIKICAgICAgICBpZiBbICJcJChjYXQgL2V0Yy9ncm91cCB8IGdyZXAgOlwke1NPQ0tFVF9HSUR9OikiID0gIiIgXTsgdGhlbgogICAgICAgICAgICBzdWRvSWYgZ3JvdXBhZGQgLS1naWQgXCR7U09DS0VUX0dJRH0gZG9ja2VyLWhvc3QKICAgICAgICBmaQogICAgICAgICMgQWRkIHVzZXIgdG8gZ3JvdXAgaWYgbm90IGFscmVhZHkgaW4gaXQKICAgICAgICBpZiBbICJcJChpZCAke1VTRVJOQU1FfSB8IGdyZXAgLUUgImdyb3Vwcy4qKD18LClcJHtTT0NLRVRfR0lEfVwoIikiID0gIiIgXTsgdGhlbgogICAgICAgICAgICBzdWRvSWYgdXNlcm1vZCAtYUcgXCR7U09DS0VUX0dJRH0gJHtVU0VSTkFNRX0KICAgICAgICBmaQogICAgZWxzZQogICAgICAgICMgRW5hYmxlIHByb3h5IGlmIG5vdCBhbHJlYWR5IHJ1bm5pbmcKICAgICAgICBpZiBbICEgLWYgIlwke1NPQ0FUX1BJRH0iIF0gfHwgISBwcyAtcCBcJChjYXQgXCR7U09DQVRfUElEfSkgPiAvZGV2L251bGw7IHRoZW4KICAgICAgICAgICAgbG9nICJFbmFibGluZyBzb2NrZXQgcHJveHkuIgogICAgICAgICAgICBsb2cgIlByb3h5aW5nICR7U09VUkNFX1NPQ0tFVH0gdG8gJHtUQVJHRVRfU09DS0VUfSBmb3IgdnNjb2RlIgogICAgICAgICAgICBzdWRvSWYgcm0gLXJmICR7VEFSR0VUX1NPQ0tFVH0KICAgICAgICAgICAgKHN1ZG9JZiBzb2NhdCBVTklYLUxJU1RFTjoke1RBUkdFVF9TT0NLRVR9LGZvcmssbW9kZT02NjAsdXNlcj0ke1VTRVJOQU1FfSBVTklYLUNPTk5FQ1Q6JHtTT1VSQ0VfU09DS0VUfSAyPiYxIHwgc3Vkb0lmIHRlZSAtYSBcJHtTT0NBVF9MT0d9ID4gL2Rldi9udWxsICYgZWNobyAiXCQhIiB8IHN1ZG9JZiB0ZWUgXCR7U09DQVRfUElEfSA+IC9kZXYvbnVsbCkKICAgICAgICBlbHNlCiAgICAgICAgICAgIGxvZyAiU29ja2V0IHByb3h5IGFscmVhZHkgcnVubmluZy4iCiAgICAgICAgZmkKICAgIGZpCiAgICBsb2cgIlN1Y2Nlc3MiCmZpCgojIEV4ZWN1dGUgd2hhdGV2ZXIgY29tbWFuZHMgd2VyZSBwYXNzZWQgaW4gKGlmIGFueSkuIFRoaXMgYWxsb3dzIHVzCiMgdG8gc2V0IHRoaXMgc2NyaXB0IHRvIEVOVFJZUE9JTlQgd2hpbGUgc3RpbGwgZXhlY3V0aW5nIHRoZSBkZWZhdWx0IENNRC4Kc2V0ICtlCmV4ZWMgIlwkQCIKRU9GCmNobW9kICt4IC91c3IvbG9jYWwvc2hhcmUvZG9ja2VyLWluaXQuc2gKY2hvd24gJHtVU0VSTkFNRX06cm9vdCAvdXNyL2xvY2FsL3NoYXJlL2RvY2tlci1pbml0LnNoCmVjaG8gIkRvbmUhIg=="
export SPACESTATION_DOCKERFILECONTENTS_BASE64="RlJPTSB1YnVudHU6bGF0ZXN0DQpFWFBPU0UgMjINCkFSRyBTUEFDRVNUQVRJT05fVVNFUg0KQVJHIFBSSVZfS0VZDQpBUkcgUFVCX0tFWQ0KQVJHIFNQQUNFU1RBVElPTl9ET0NLRVJXUkFQUEVSQ09OVEVOVFNfQkFTRTY0DQpFTlYgU1BBQ0VTVEFUSU9OX0RPQ0tFUldSQVBQRVI9Ii91c3IvbG9jYWwvYmluL2RvY2tlci13cmFwcGVyIg0KDQojIEluc3RhbGwgRG9ja2VyICsgZGVwZW5kZW5jaWVzIGFuZCBSU3luYyBhbmQgU1NIIFNlcnZlcg0KUlVOIGFwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQgaW5zdGFsbCAteSBcDQogIGFwdC11dGlscyBcDQogIGFwdC10cmFuc3BvcnQtaHR0cHMgXA0KICBjYS1jZXJ0aWZpY2F0ZXMgXA0KICBjdXJsIFwNCiAgbHhjIFwNCiAgaXB0YWJsZXMgXA0KICBvcGVuc3NoLXNlcnZlciBcDQogIGlwcm91dGUyIFwgIA0KICBzdWRvIFwgICAgICANCiAgZ251cGcgXA0KICBsc2ItcmVsZWFzZSBcICANCiAgY3JvbiBcICANCiAgbGlicGFtLWNnZnMgXA0KICBhY2wNCg0KUlVOIGN1cmwgLWZzU0wgaHR0cHM6Ly9kb3dubG9hZC5kb2NrZXIuY29tL2xpbnV4L3VidW50dS9ncGcgfCBncGcgLS1kZWFybW9yIC1vIC91c3Ivc2hhcmUva2V5cmluZ3MvZG9ja2VyLWFyY2hpdmUta2V5cmluZy5ncGcNCiAgIA0KUlVOIGVjaG8gXA0KICAgICAgImRlYiBbYXJjaD0kKGRwa2cgLS1wcmludC1hcmNoaXRlY3R1cmUpIHNpZ25lZC1ieT0vdXNyL3NoYXJlL2tleXJpbmdzL2RvY2tlci1hcmNoaXZlLWtleXJpbmcuZ3BnXSBodHRwczovL2Rvd25sb2FkLmRvY2tlci5jb20vbGludXgvdWJ1bnR1IFwNCiAgICAgICQobHNiX3JlbGVhc2UgLWNzKSBzdGFibGUiID4gL2V0Yy9hcHQvc291cmNlcy5saXN0LmQvZG9ja2VyLmxpc3QNCiAgIA0KUlVOIGFwdC1nZXQgdXBkYXRlIFwNCiAgICYmIGFwdC1nZXQgLXkgaW5zdGFsbCBkb2NrZXItY2UgZG9ja2VyLWNlLWNsaSBjb250YWluZXJkLmlvDQpSVU4gYWRkdXNlciAtdSA1Njc4IC0tZGlzYWJsZWQtcGFzc3dvcmQgLS1nZWNvcyAiIiAke1NQQUNFU1RBVElPTl9VU0VSfQ0KDQoNClJVTiBlY2hvICRTUEFDRVNUQVRJT05fRE9DS0VSV1JBUFBFUkNPTlRFTlRTX0JBU0U2NCA+IC90bXAvZG9ja2VyV3JhcHBlci5iYXNlNjQgJiYgYmFzZTY0IC0tZGVjb2RlIC90bXAvZG9ja2VyV3JhcHBlci5iYXNlNjQgPiAkU1BBQ0VTVEFUSU9OX0RPQ0tFUldSQVBQRVINClJVTiBjaG1vZCAreCAiJFNQQUNFU1RBVElPTl9ET0NLRVJXUkFQUEVSIiANCg0KIyBXcml0ZSB0aGUgcHJpdmF0ZSBhbmQgcHVibGljIGtleXMgdG8gdGhlIG5ldyB1c2VyJ3MgZW52aXJvbm1lbnQuICBVcGRhdGUgcGVybWlzc2lvbnMgb24gdGhlIGdyb3VuZHN0YXRpb24gZGlyZWN0b3J5IHNvIHRoZSB1c2VyIGNhbiByZWFkL3dyaXRlIHRvIGl0DQpSVU4gbWtkaXIgLXAgL2hvbWUvJHtTUEFDRVNUQVRJT05fVVNFUn0vLnNzaCAgJiYgXA0KICAgIG1rZGlyIC1wIC9ob21lLyR7U1BBQ0VTVEFUSU9OX1VTRVJ9L2Zyb21Hcm91bmRTdGF0aW9uICAmJiBcDQogICAgbWtkaXIgLXAgL2hvbWUvJHtTUEFDRVNUQVRJT05fVVNFUn0vdG9Hcm91bmRTdGF0aW9uICAmJiBcDQogICAgZWNobyAiJFBSSVZfS0VZIiA+IC9ob21lLyR7U1BBQ0VTVEFUSU9OX1VTRVJ9Ly5zc2gvaWRfcnNhICYmIFwNCiAgICBlY2hvICIkUFVCX0tFWSIgPiAvaG9tZS8ke1NQQUNFU1RBVElPTl9VU0VSfS8uc3NoL2lkX3JzYS5wdWIgJiYgXA0KICAgIGNobW9kIDYwMCAvaG9tZS8ke1NQQUNFU1RBVElPTl9VU0VSfS8uc3NoL2lkX3JzYSAmJiBcDQogICAgY2htb2QgNjAwIC9ob21lLyR7U1BBQ0VTVEFUSU9OX1VTRVJ9Ly5zc2gvaWRfcnNhLnB1YiAmJiBcDQogICAgY2htb2QgMTc3NyAvaG9tZS8ke1NQQUNFU1RBVElPTl9VU0VSfS9mcm9tR3JvdW5kU3RhdGlvbiAmJiBcDQogICAgY2htb2QgMTc3NyAvaG9tZS8ke1NQQUNFU1RBVElPTl9VU0VSfS90b0dyb3VuZFN0YXRpb24gJiYgXA0KICAgIGNhdCAvaG9tZS8ke1NQQUNFU1RBVElPTl9VU0VSfS8uc3NoL2lkX3JzYS5wdWIgPj4gL2hvbWUvJHtTUEFDRVNUQVRJT05fVVNFUn0vLnNzaC9hdXRob3JpemVkX2tleXMgJiYgXA0KICAgIGVjaG8gJHtTUEFDRVNUQVRJT05fVVNFUn0gQUxMPVwocm9vdFwpIE5PUEFTU1dEOkFMTCA+IC9ldGMvc3Vkb2Vycy5kLyR7U1BBQ0VTVEFUSU9OX1VTRVJ9IFwNCiAgICBjaG1vZCAwNDQwIC9ldGMvc3Vkb2Vycy5kLyR7U1BBQ0VTVEFUSU9OX1VTRVJ9DQoNCiMgVHdlYWsgdGhlIFNTSCBjb25maWcgc28gd2UgY2FuIHJ1biBpdA0KUlVOIHNlZCAtaScnIC1lJ3MvXiNQZXJtaXRSb290TG9naW4gcHJvaGliaXQtcGFzc3dvcmQkL1Blcm1pdFJvb3RMb2dpbiB5ZXMvJyAvZXRjL3NzaC9zc2hkX2NvbmZpZyBcDQogICAgICAgICYmIHNlZCAtaScnIC1lJ3MvXiNQYXNzd29yZEF1dGhlbnRpY2F0aW9uIHllcyQvUGFzc3dvcmRBdXRoZW50aWNhdGlvbiBuby8nIC9ldGMvc3NoL3NzaGRfY29uZmlnIFwNCiAgICAgICAgJiYgc2VkIC1pJycgLWUncy9eI1Blcm1pdEVtcHR5UGFzc3dvcmRzIG5vJC9QZXJtaXRFbXB0eVBhc3N3b3JkcyB5ZXMvJyAvZXRjL3NzaC9zc2hkX2NvbmZpZyBcDQogICAgICAgICYmIHNlZCAtaScnIC1lJ3MvXlVzZVBBTSB5ZXMvVXNlUEFNIG5vLycgL2V0Yy9zc2gvc3NoZF9jb25maWcgJiYgc2VydmljZSBzc2ggc3RhcnQNCg0KDQojIFN0YXJ0IHVwIHRoZSBTU0ggU2VydmVyIERhZW1vbiBhbmQgdGhlIGRvY2tlci1pbi1kb2NrZXIgd3JhcHBlciBzY3JpcHQNCkNNRCBbInNoIiwgIi1jIiwgIi91c3Ivc2Jpbi9zc2hkIDsgL2Jpbi9iYXNoIl0NCg0KDQojIFVTRVIgJFNQQUNFU1RBVElPTl9VU0VSDQojV09SS0RJUiAkR1JPVU5EU1RBVElPTl9ST09URElS"
export GROUNDSTATION_SSHKEY="${HOME}/.ssh/id_rsa_spaceStation"
export PROVISIONING_LOG="${GROUNDSTATION_LOGS}/deployGroundStation.log"
export SPACESTATION_NETWORK_NAME="spaceDevVNet"
export SPACESTATION_CONTAINER_NAME="mockspacestation"
export GROUNDSTATION_VERSION="2.1"

GROUNDSTATION_USER=$(whoami)

# ********************************************************
# Miscellaneous Directories: START
# ********************************************************
sudo mkdir -p "$GROUNDSTATION_LOGS"
sudo mkdir -p "$GROUNDSTATION_OUTBOX"
sudo mkdir -p "$GROUNDSTATION_INBOX"
sudo mkdir -p "$HOME"/.ssh
sudo mkdir -p "$GROUNDSTATION_ROOTDIR"
sudo chown -R "$GROUNDSTATION_USER" "$GROUNDSTATION_ROOTDIR"

# ********************************************************
# Miscellaneous Directories: END
# ********************************************************


# ********************************************************
# Persistant Variables: START
# ********************************************************
#sudo bash -c 'cat > /etc/profile.d/mock-spacestation-vars.sh' << EOF
sudo bash -c 'cat >> /etc/bash.bashrc' << EOF
export GROUNDSTATION_LOGS="${GROUNDSTATION_ROOTDIR}"
export GROUNDSTATION_OUTBOX="${GROUNDSTATION_OUTBOX}"
export GROUNDSTATION_INBOX="${GROUNDSTATION_INBOX}"
export GROUNDSTATION_DinD="${GROUNDSTATION_DinD}"
export GROUNDSTATION_DinD_CONTENTSBASE64="${GROUNDSTATION_DinD_CONTENTSBASE64}"
export GROUNDSTATION_SSHKEY="${GROUNDSTATION_SSHKEY}"
export PROVISIONING_LOG="${PROVISIONING_LOG}"
export SPACESTATION_NETWORK_NAME="${SPACESTATION_NETWORK_NAME}"
export SPACESTATION_CONTAINER_NAME="${SPACESTATION_CONTAINER_NAME}"
export GROUNDSTATION_ROOTDIR="${GROUNDSTATION_ROOTDIR}"
export GROUNDSTATION_USER="${GROUNDSTATION_USER}"
export GROUNDSTATION_DinD_CONTENTSBASE64="${GROUNDSTATION_DinD_CONTENTSBASE64}"
export SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="${SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64}"
echo ""
echo ""
echo ""
echo ""
figlet Azure Mock SpaceStation
echo ""
echo ""
echo "Welcome to the Mock SpaceStation Template (https://github.com/azure/mock-spacestation) v2.1!"
echo ""
echo "This environment emulates the configuration and networking constraints observed by the Microsoft Azure Space Team while developing their genomics experiment to run on the International Space Station"
echo ""
echo "You are connected to the GroundStation"
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!" 

EOF

# ********************************************************
# Persistant Variables: END
# ********************************************************

if [[ $(whoami) -ne  $GROUNDSTATION_USER ]] ; then echo "Please rerun this script as user '$GROUNDSTATION_USER'." ; exit 1 ; fi

writeToProvisioningLog () {
    echo "$(date +%Y-%m-%d-%H%M%S): $1"
    echo "$(date +%Y-%m-%d-%H%M%S): $1" >> "$PROVISIONING_LOG"
}

# ********************************************************
# Setup Docker: START
# ********************************************************
sudo touch "$PROVISIONING_LOG"
sudo chown "$GROUNDSTATION_USER" "$PROVISIONING_LOG" 
sudo chmod 777 "$PROVISIONING_LOG"
writeToProvisioningLog "Starting Mock SpaceStation Configuration (v $GROUNDSTATION_VERSION)"
writeToProvisioningLog "-----------------------------------------------------------"
writeToProvisioningLog "Working Dir: ${PWD}"
writeToProvisioningLog "Installing libraries"
writeToProvisioningLog "Deploy Docker in GroundStation (START)"
writeToProvisioningLog "$(printenv)"

sudo apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && sudo apt-get -y install --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    flock \
    cron \
    trickle \
    libpam-cgfs \
    acl \
    figlet


writeToProvisioningLog "Installing regular Docker"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

sudo echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update \
&& sudo apt-get -y install docker-ce docker-ce-cli containerd.io

ISREMOTECONTAINER=$(printenv | grep "REMOTE_CONTAINER")

if [ -n "${ISREMOTECONTAINER}" ]; then    
    writeToProvisioningLog "...Enabling Docker in Docker"

    writeToProvisioningLog "...Writing Docker-in-Docker wrapper file to '$GROUNDSTATION_DinD'..."
    #Decode the DinD wrapper file embedded in the variable and write to the real file.  This keeps us needing only one uber file
    #base64 -w0 filename
    echo $GROUNDSTATION_DinD_CONTENTSBASE64 | base64 --decode | sudo tee $GROUNDSTATION_DinD > /dev/null
    sudo chmod +x "$GROUNDSTATION_DinD"

    sudo bash $GROUNDSTATION_DinD  
fi
sudo usermod -aG docker "$GROUNDSTATION_USER"
sudo setfacl -m user:"$GROUNDSTATION_USER":rw /var/run/docker.sock

writeToProvisioningLog "Docker installed"


# ********************************************************
# Setup Docker: END
# ********************************************************



# ********************************************************
# Generate SSH Keys: START
# ********************************************************
writeToProvisioningLog "SSH Key Generation in GroundStation (START)"
sudo chmod 0700 "$HOME"/.ssh
ssh-keygen -t rsa -b 4096 -q -N '' -f "$GROUNDSTATION_SSHKEY"
sudo chmod 600 "$GROUNDSTATION_SSHKEY" && \
sudo chmod 600 "$GROUNDSTATION_SSHKEY".pub && \
cat "${GROUNDSTATION_SSHKEY}".pub >> /home/"${GROUNDSTATION_USER}"/.ssh/authorized_keys && \
writeToProvisioningLog "SSH Key Generation in GroundStation (COMPLETE)"

# ********************************************************
# Generate SSH Keys: END
# ********************************************************


# ********************************************************
# Configure Docker: START
# ********************************************************
writeToProvisioningLog "Docker Config (START)"
APPNETWORK=$(sudo docker network ls --format '{{.Name}}' | grep "${SPACESTATION_NETWORK_NAME}")
if [ -z "${APPNETWORK}" ]; then
    writeToProvisioningLog "Creating docker network '$SPACESTATION_NETWORK_NAME'..."
    sudo docker network create --driver bridge --internal "$SPACESTATION_NETWORK_NAME"
    writeToProvisioningLog "Docker network '$SPACESTATION_NETWORK_NAME' created"
else
    writeToProvisioningLog "Docker network '$SPACESTATION_NETWORK_NAME' already exists"
fi

writeToProvisioningLog "Docker Config (COMPLETE)"

# ********************************************************
# Configure Docker: END
# ********************************************************


# ********************************************************
# Deploy SpaceStation Container: START
# ********************************************************
# docker container rm mockspacestation -f
# docker image rm mockspacestation-img
# docker container attach mockspacestation
# base64 -w0 ./.devcontainer/setupScripts/Dockerfile.SpaceStation > output.txt
writeToProvisioningLog "Building Space Station Image '$SPACESTATION_CONTAINER_NAME-img'..."
echo $SPACESTATION_DOCKERFILECONTENTS_BASE64 | base64 --decode | sudo tee /tmp/Dockerfile.SpaceStation > /dev/null
sudo chown "$GROUNDSTATION_USER" /tmp/Dockerfile.SpaceStation
sudo chmod 1777 /tmp/Dockerfile.SpaceStation

sudo docker build -t "$SPACESTATION_CONTAINER_NAME-img" --no-cache  --build-arg SPACESTATION_USER="$GROUNDSTATION_USER" --build-arg PRIV_KEY="$(cat $GROUNDSTATION_SSHKEY)" --build-arg PUB_KEY="$(cat $GROUNDSTATION_SSHKEY.pub)" --build-arg SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="$GROUNDSTATION_DinD_CONTENTSBASE64" --file /tmp/Dockerfile.SpaceStation .
writeToProvisioningLog "Space Station Image '$SPACESTATION_CONTAINER_NAME-img' successfully built"

writeToProvisioningLog "Starting Space Station Container '$SPACESTATION_CONTAINER_NAME'..."
sudo docker run -dit --privileged --hostname "$SPACESTATION_CONTAINER_NAME" --name "$SPACESTATION_CONTAINER_NAME" --network "$SPACESTATION_NETWORK_NAME" "$SPACESTATION_CONTAINER_NAME-img" 

sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "/usr/local/bin/docker-wrapper"
sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "setfacl -m user:$GROUNDSTATION_USER:rw /var/run/docker.sock"
writeToProvisioningLog "'$SPACESTATION_CONTAINER_NAME' started..."

# ********************************************************
# Deploy SpaceStation Container: END
# ********************************************************




# ********************************************************
# Build SSH and RSYNC Jobs: START
# ********************************************************

sudo apt-get -y install --no-install-recommends trickle cron


writeToProvisioningLog "Building SSH connection to '$SPACESTATION_CONTAINER_NAME'..."
#mockSpaceStationIP=$(sudo docker inspect mockspacestation --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
{
    echo '#!/bin/bash'
    echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'    
    echo 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$GROUNDSTATION_SSHKEY" "$GROUNDSTATION_USER"@"$mockSpaceStationIP"'
} > ${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

sudo chmod +x ${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

writeToProvisioningLog "Building sync job to '$SPACESTATION_CONTAINER_NAME' (${GROUNDSTATION_ROOTDIR}/sync-to-spacestation.sh)..."

{
    echo '#!/bin/bash'    
    echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
    echo "GROUNDSTATION_SSHKEY=$GROUNDSTATION_SSHKEY"
    echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
    echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
    echo "Starting push to SpaceStation..."
    echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
    echo "Starting pull from SpaceStation..."
    echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'    
} > /tmp/sync-to-spacestation.sh

sudo chmod +x /tmp/sync-to-spacestation.sh
sudo chmod 1777 /tmp/sync-to-spacestation.sh

{
    echo '#!/bin/bash'
    echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
    echo "GROUNDSTATION_SSHKEY=$GROUNDSTATION_SSHKEY"
    echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
    echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
    echo "Starting push to SpaceStation..."
    echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
    echo "Starting pull from SpaceStation..."
    echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'    
} > /tmp/sync-to-spacestation-noThrottle.sh

sudo chmod +x /tmp/sync-to-spacestation-noThrottle.sh
sudo chmod 1777 /tmp/sync-to-spacestation-noThrottle.sh


echo "* * * * * /usr/bin/flock -w 0 /tmp/sync-to-spacestation-job.lock /tmp/sync-to-spacestation.sh >> $GROUNDSTATION_LOGS/sync-to-spacestation.log 2>&1" > /tmp/sync-to-spacestation-job
crontab /tmp/sync-to-spacestation-job
sudo service cron start
#crontab -l #list cron jobs
#crontab -r #remove cron jobs

# ********************************************************
# Build SSH and RSYNC Jobs: END
# ********************************************************
sudo apt-get install -y figlet

clear
figlet Azure Mock SpaceStation
echo ""
echo ""
echo "Welcome to the Mock SpaceStation Template (https://github.com/azure/mock-spacestation) v2.1!"
echo ""
echo "This environment emulates the configuration and networking constraints observed by the Microsoft Azure Space Team while developing their genomics experiment to run on the International Space Station"
echo ""
echo "You are connected to the GroundStation"
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!" 
cd "$GROUNDSTATION_ROOTDIR" || exit