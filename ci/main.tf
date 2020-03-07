data "external" "machine" {
    program = ["./select_machine.py", var.packet_token]
}

provider "packet" {
    auth_token = var.packet_token
}

resource "packet_spot_market_request" "req" {
    project_id       = var.project_id
    max_bid_price    = tonumber(data.external.machine.result.price)
    facilities       = [data.external.machine.result.location]
    devices_min      = 1
    devices_max      = 1
    wait_for_devices = true

    instance_parameters {
        hostname         = var.hostname
        plan             = data.external.machine.result.type
        billing_cycle    = "hourly"
        operating_system = "ubuntu_18_04"
    }
}

data "packet_spot_market_request" "dreq" {
    request_id = packet_spot_market_request.req.id
}

data "packet_device" "device" {
    device_id = data.packet_spot_market_request.dreq.device_ids[0]
}

resource "null_resource" "build" {
    triggers = {
        ip = data.packet_device.device.access_public_ipv4
    }

    connection {
        host = data.packet_device.device.access_public_ipv4
        private_key = var.packet_ssh_key
        timeout = "10s"
    }

    provisioner "file" {
        source      = "build_agent.sh"
        destination = "/tmp/build.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/build.sh",
            "export GH_USER=${var.github_user} GH_TOKEN=${var.github_token} GH_BUILD_REPO=${var.github_build_repo} GH_REL_REPO=${var.github_release_repo} GH_RUN_ID=${var.github_run_id} TG_CHAT_ID=${var.telegram_chat_id} TG_TOKEN=${var.telegram_token} GIT_NAME=${var.git_author_name} GIT_EMAIL=${var.git_author_email}",
            "/tmp/build.sh"
        ]
    }
}
