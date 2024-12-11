
# AWS Security Group Rule Manager (Multi-Security Group Support)

This script manages AWS Security Group rules for multiple security groups by:
- Adding or updating rules for specified ports and tags.
- Removing older rules with the same tag but mismatched CIDR blocks.
- Tagging the rules for easy identification and management.

## Features

- Dynamically fetches your public IP for CIDR-based rule updates.
- Ensures no duplicate rules are created.
- Automatically removes outdated rules for specified ports and tags.
- Supports multiple security groups and multiple rules with custom tags for each.

---

## Prerequisites

1. **AWS CLI**: Install and configure the AWS CLI. Follow [this guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) if it's not already set up.
   ```bash
   aws configure
   ```

2. **jq**: Install `jq` for JSON parsing:
   - macOS: `brew install jq`
   - Ubuntu: `sudo apt-get install jq`
   - Windows: Use the [jq binary](https://stedolan.github.io/jq/download/).

3. **IAM Permissions**: Ensure your AWS CLI profile has the following permissions:
   - `ec2:DescribeSecurityGroupRules`
   - `ec2:AuthorizeSecurityGroupIngress`
   - `ec2:RevokeSecurityGroupIngress`
   - `ec2:CreateTags`

---

## Setup

1. Clone or download the script:
   ```bash
   git clone https://github.com/your-repo/aws-security-group-rule-manager.git
   cd aws-security-group-rule-manager
   ```

2. Update the script variables:
   - Open the script in a text editor:
     ```bash
     nano update-Ip-ValetEZ-new.sh
     ```
   - Update the following variables:
     ```bash
     SECURITY_GROUP_IDS=("sg-xxxxxxxxxxxx" "sg-xxxxxxxxxxxxxx")  # Replace with your Security Group IDs
     AWS_PROFILE="your-profile-name"                                     # Replace with your AWS CLI profile name (leave empty if default)
     ```

3. Define your rules:
   - Add rules in the `RULES_TO_CONFIGURE` array. Each rule consists of:
     - The port number.
     - A tag key-value pair for the rule.
   - Example:
     ```bash
     RULES_TO_CONFIGURE=(
         "22:RuleType=shehzad-ssh-access"
         "3306:RuleType=shehzad-mysql-access"
     )
     ```

---

## How to Run

1. Make the script executable:
   ```bash
   chmod +x update-Ip-ValetEZ-new.sh
   ```

2. Run the script:
   ```bash
   ./update-Ip-ValetEZ-new.sh
   ```

---

## Script Workflow

1. **Fetch Rules**:
   - Retrieves all existing rules for each specified security group.

2. **Check for Existing Rules**:
   - If a rule with the same port, protocol, CIDR, and tag exists, it skips updating.

3. **Remove Older Rules**:
   - Deletes rules with matching ports and tags but mismatched CIDRs.

4. **Add or Update Rules**:
   - Adds a new rule if no matching rule exists.
   - Tags the rule with the specified key-value pair.

5. **Multiple Security Groups**:
   - The script processes each security group in the `SECURITY_GROUP_IDS` array independently.

---

## Example Output

### When Adding a New Rule:
```plaintext
Updating rule for Security Group: sg-070912c0108c0cfb6, Port: 22, Tag: RuleType=shehzad-ssh-access, IP: 223.233.81.192/32...
Adding or updating rule for Security Group: sg-070912c0108c0cfb6, Port: 22, IP: 223.233.81.192/32...
Tagging rule: sgr-0e68ff6d12e50646f with RuleType=shehzad-ssh-access...
Rule created and tagged successfully.
```

### When Removing an Outdated Rule:
```plaintext
Updating rule for Security Group: sg-070912c0108c0cfb6, Port: 22, Tag: RuleType=shehzad-ssh-access, IP: 223.233.81.192/32...
Deleting older rules for Security Group: sg-070912c0108c0cfb6, Port: 22, Tag: RuleType=shehzad-ssh-access and mismatched CIDR...
Deleted rule ID: sgr-0123456789abcdef0
Adding or updating rule for Security Group: sg-070912c0108c0cfb6, Port: 22, IP: 223.233.81.192/32...
Tagging rule: sgr-0e68ff6d12e50646f with RuleType=shehzad-ssh-access...
Rule created and tagged successfully.
```

### When No Changes Are Needed:
```plaintext
Updating rule for Security Group: sg-080912c0108c0cfa6, Port: 3306, Tag: RuleType=shehzad-mysql-access, IP: 223.233.81.192/32...
Rule already exists for Security Group: sg-080912c0108c0cfa6, Port: 3306, Tag: RuleType=shehzad-mysql-access. Skipping update.
```

---

## Notes

- The script works with **inbound rules** only. Modify for outbound rules if needed.
- Ensure your security groups have enough room for new rules (up to 50 rules per security group).
- The `jq` tool is critical for filtering rules. Ensure it is installed and functional.

