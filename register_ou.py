import boto3
import json
import argparse

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
                    print("ERROR: OU already registered")
                    exit()
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
    print(enable_baseline_response)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ou_arn', help="OU ARN")
    args = parser.parse_args()
    ouARN = args.ou_arn

    # Precheck to validate the ou is already registered or not
    check("targetIdentifier", ouARN, "registration_check")

    for baseline in baselines_response["baselines"]:
        if baseline["name"] == "IdentityCenterBaseline":
            identityCenterBaselineARN = baseline["arn"]
        if baseline["name"] == "AWSControlTowerBaseline":
            awsControlTowerBaselineARN = baseline["arn"]

    if identityCenterBaselineARN != "" and awsControlTowerBaselineARN != "":
        # Get IdentityCenterEnabledBaselineArn
        identityCenterEnabledBaselineArn = check("baselineIdentifier", identityCenterBaselineARN, "getidentityCenterBaselineARN")
        if identityCenterEnabledBaselineArn != "":
            # Register the Organization Unit
            registerOU(awsControlTowerBaselineARN, ouARN, identityCenterEnabledBaselineArn)
        else:
            print("ERROR: NOT FOUND IdentityCenterEnabledBaselineArn")
            exit()
    else:
        print("ERROR: NOT FOUND IdentityCenterBaseline/AWSControlTowerBaseline")
        exit()