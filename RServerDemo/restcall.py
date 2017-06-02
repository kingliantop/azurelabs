# -*- coding: utf-8 -*-
"""
Created on Sat May 20 00:08:52 2017
Demo for the R service REST call
@author: Steven Lian
"""

import mt_service1495184382 as mt
import mt_service1495184382.models as models

from requests.utils import to_key_val_list, default_headers


login = models.LoginRequest("admin","Ning9346527!")

mtp = mt.MtService1495184382("http://42.159.115.154:12800")

token=mtp.login(login)

print(token)

input = models.InputParameters(120,2.8)

headers=default_headers()

headers['Authorization'] = "{} {}".format(token.token_type, token.access_token)


result = mtp.manual_transmission(input,headers)

print(result.output_parameters)
