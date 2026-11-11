package main

import rego.v1

# Ports that must never be exposed to the internet
admin_ports := {22, 3389, 5432, 3306, 1433, 6379}

# HCL blocks parse as an object when there is one, a list when there are several
as_list(x) := x if is_array(x)

as_list(x) := [x] if is_object(x)

open_world(cidrs) if {
	some c in cidrs
	c in {"0.0.0.0/0", "::/0"}
}

deny contains msg if {
	some name, sg in input.resource.aws_security_group
	some rule in as_list(sg.ingress)
	open_world(rule.cidr_blocks)
	some port in admin_ports
	rule.from_port <= port
	port <= rule.to_port
	msg := sprintf(
		"BLOCKED: aws_security_group.%s exposes admin port %d to the internet. Use a bastion, SSM Session Manager, or a trusted CIDR.",
		[name, port],
	)
}

deny contains msg if {
	some name, sg in input.resource.aws_security_group
	not sg.tags.owner
	msg := sprintf("BLOCKED: aws_security_group.%s has no 'owner' tag. Every resource needs an accountable owner.", [name])
}
