#!/bin/bash

# Configuration
SECURITY_GROUP_IDS=("sg-xxxxxxxxxxxxx" "sg-xxxxxxxxxxxxxx")  # Replace with your Security Group IDs
AWS_PROFILE="my-profile"                    # Optional AWS profile
PROTOCOL="tcp"                           # Protocol (default: tcp)
CIDR=$(curl -s https://checkip.amazonaws.com)/32  # Current public IP CIDR

# AWS CLI Profile Flag (if provided)
PROFILE_FLAG=""
if [[ -n "$AWS_PROFILE" ]]; then
    PROFILE_FLAG="--profile $AWS_PROFILE"
fi

# Rules to configure: Port and Tag Key-Value pairs
RULES_TO_CONFIGURE=(
    "22:RuleType=shehzad-ssh-access"
    "3306:RuleType=shehzad-mysql-access"
)

# Function to update or tag an existing rule
update_rule() {
    local SECURITY_GROUP_ID=$1
    local PORT=$2
    local TAG_KEY=$(echo "$3" | awk -F= '{print $1}')
    local TAG_VALUE=$(echo "$3" | awk -F= '{print $2}')

    echo "Updating rule for Security Group: $SECURITY_GROUP_ID, Port: $PORT, Tag: $TAG_KEY=$TAG_VALUE, IP: $CIDR..."

    # Fetch all rules for the security group
    ALL_RULES=$(aws ec2 describe-security-group-rules \
        $PROFILE_FLAG \
        --filters "Name=group-id,Values=$SECURITY_GROUP_ID" \
        --query "SecurityGroupRules" \
        --output json)

    # Find older rules with the same tag but a different CIDR
    RULE_IDS_TO_DELETE=$(echo "$ALL_RULES" | jq -r \
        ".[] | select(.FromPort == $PORT and .ToPort == $PORT and .IpProtocol == \"$PROTOCOL\" and .Tags[]?.Key == \"$TAG_KEY\" and .Tags[]?.Value == \"$TAG_VALUE\" and .CidrIpv4 != \"$CIDR\") | .SecurityGroupRuleId")

    # Delete older rules if any
    if [[ -n "$RULE_IDS_TO_DELETE" ]]; then
        echo "Deleting older rules for Security Group: $SECURITY_GROUP_ID, Port: $PORT, Tag: $TAG_KEY=$TAG_VALUE and mismatched CIDR..."
        for RULE_ID in $RULE_IDS_TO_DELETE; do
            aws ec2 revoke-security-group-ingress \
                --group-id "$SECURITY_GROUP_ID" \
                $PROFILE_FLAG \
                --security-group-rule-ids "$RULE_ID"
            echo "Deleted rule ID: $RULE_ID"
        done
    else
        echo "No older rules to delete for Security Group: $SECURITY_GROUP_ID, Port: $PORT, Tag: $TAG_KEY=$TAG_VALUE."
    fi

    # Check if a rule exists with matching CIDR, port, and tag
    RULE_ID=$(echo "$ALL_RULES" | jq -r \
        ".[] | select(.FromPort == $PORT and .ToPort == $PORT and .IpProtocol == \"$PROTOCOL\" and .CidrIpv4 == \"$CIDR\" and .Tags[]?.Key == \"$TAG_KEY\" and .Tags[]?.Value == \"$TAG_VALUE\") | .SecurityGroupRuleId")

    if [[ -n "$RULE_ID" ]]; then
        echo "Rule already exists for Security Group: $SECURITY_GROUP_ID, Port: $PORT, Tag: $TAG_KEY=$TAG_VALUE. Skipping update."
        return
    fi

    # Add or update the rule
    echo "Adding or updating rule for Security Group: $SECURITY_GROUP_ID, Port: $PORT, IP: $CIDR..."
    RULE_OUTPUT=$(aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        $PROFILE_FLAG \
        --protocol "$PROTOCOL" \
        --port "$PORT" \
        --cidr "$CIDR" \
        --output json)

    # Extract the rule ID from the output
    NEW_RULE_ID=$(echo "$RULE_OUTPUT" | jq -r '.SecurityGroupRules[0].SecurityGroupRuleId')

    # Tag the rule with the specified key-value pair
    if [[ -n "$NEW_RULE_ID" ]]; then
        echo "Tagging rule: $NEW_RULE_ID with $TAG_KEY=$TAG_VALUE..."
        aws ec2 create-tags \
            --resources "$NEW_RULE_ID" \
            --tags Key="$TAG_KEY",Value="$TAG_VALUE" \
            $PROFILE_FLAG
        echo "Rule created and tagged successfully."
    else
        echo "Failed to create or tag the rule."
    fi
}

# Main execution: Iterate through SECURITY_GROUP_IDS and RULES_TO_CONFIGURE
for SECURITY_GROUP_ID in "${SECURITY_GROUP_IDS[@]}"; do
    for RULE in "${RULES_TO_CONFIGURE[@]}"; do
        IFS=":" read -r PORT TAG <<< "$RULE"
        update_rule "$SECURITY_GROUP_ID" "$PORT" "$TAG"
    done
done

