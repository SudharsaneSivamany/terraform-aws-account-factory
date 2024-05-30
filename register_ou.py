# MIT License

# Copyright (c) 2024 Sudharsane Sivamany

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import boto3
import json
import argparse
import time

client = boto3.client('controltower')

baselines_response = client.list_baselines()

ouARN = "" 

identityCenterBaselineARN = ""
awsControlTowerBaselineARN = ""
identityCenterEnabledBaselineArn = ""



def check(key, value, types):
    list_enabled_baselines_response = client.list_enabled_baselines()
    for enabledBaseline in list_enabled_baselines_response["enabledBaselines"]:
        if enabledBaseline[key] == value:
            if types == "registration_check":
                if enabledBaseline["statusSummary"]["status"] == "SUCCEEDED":
                    return True
                else:
                    return False
            elif types == "registration_update_check":
                if enabledBaseline["statusSummary"]["status"] == "UNDER_CHANGE":
                    return True
                else: 
                    return False
            else:
                identityCenterEnabledBaselineArn = enabledBaseline["arn"]
                return identityCenterEnabledBaselineArn

def registerOU(awsControlTowerBaselineARN, ouARN, identityCenterEnabledBaselineArn):
    enable_baseline_response = client.enable_baseline(
    baselineIdentifier = awsControlTowerBaselineARN,
    baselineVersion = "4.0",
    targetIdentifier = ouARN,
    parameters = [
        {
            "key": "IdentityCenterEnabledBaselineArn",
            "value": identityCenterEnabledBaselineArn
        },
    ]
    )
    time.sleep(10) 
    if enable_baseline_response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        while(check("targetIdentifier", ouARN, "registration_update_check")):
            time.sleep(15)
        if check("targetIdentifier", ouARN, "registration_check"): 
            print("\033[1;32;40m$$$ %s Registered Successfully!  $$$" % ouARN)
        else:
            print("\033[1;31;40m$$$ %s Registration Failed  $$$" % ouARN)
    else:
        print(enable_baseline_response)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ou_arn', help="OU ARN")
    args = parser.parse_args()
    ouARN = args.ou_arn

    list_ouARN = ouARN.split(',')
    

    for baseline in baselines_response["baselines"]:
        if baseline["name"] == "IdentityCenterBaseline":
            identityCenterBaselineARN = baseline["arn"]
        if baseline["name"] == "AWSControlTowerBaseline":
            awsControlTowerBaselineARN = baseline["arn"]

    if identityCenterBaselineARN != "" and awsControlTowerBaselineARN != "":
        # Get IdentityCenterEnabledBaselineArn
        identityCenterEnabledBaselineArn = check("baselineIdentifier", identityCenterBaselineARN, "getidentityCenterBaselineARN")
        if identityCenterEnabledBaselineArn != "":
            for ouARN in list_ouARN:
                if not check("targetIdentifier", ouARN, "registration_check"):
                    # Register the Organization Unit
                    registerOU(awsControlTowerBaselineARN, ouARN, identityCenterEnabledBaselineArn)
                    
        else:
            print("ERROR: NOT FOUND IdentityCenterEnabledBaselineArn")
            exit()
    else:
        print("ERROR: NOT FOUND IdentityCenterBaseline/AWSControlTowerBaseline")
        exit()