#/bin/bash
KEY=$1

GROUP_ID=$(aws ec2 describe-security-groups | jq -r '.SecurityGroups[] | select(.GroupName | startswith("myeks-EKSEC2SG")).GroupId')

OLD_CIDR=$(aws ec2 describe-security-groups --group-id $GROUP_ID | jq -r '.SecurityGroups[] | select(.Description == "eksctl-host Security Group").IpPermissions[].IpRanges[].CidrIp')

#OLD_CIDR=$(aws ec2 describe-security-groups --group-id $GROUP_ID | jq -r '.SecurityGroups[].IpPermissions[].IpRanges[].CidrIp')

NEW_CIDR=$(curl https://ipinfo.io/ip)/32

RULE_ID=$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$GROUP_ID" | jq -r '.SecurityGroupRules[] | select(.CidrIpv4 | startswith("'$OLD_CIDR'")).SecurityGroupRuleId')

aws ec2 modify-security-group-rules --group-id $GROUP_ID --security-group-rules '[{"SecurityGroupRuleId":"'$RULE_ID'","SecurityGroupRule":{"IpProtocol":"-1","CidrIpv4":"'$NEW_CIDR'"}}]' > /dev/null

ssh -i $KEY ec2-user@$(aws ec2 describe-instances --filters "Name=instance.group-name,Values=myeks*" --query "Reservations[].Instances[].PublicIpAddress" --output text)
