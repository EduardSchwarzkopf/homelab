locals {
  control_plane_node = tolist(module.controlplane.hostnames)[0]
  cluster_endpoint   = "https://${local.control_plane_node}:6443"
  config_filename    = "config"
  kube_path          = "~/.kube"
  kube_config_path   = "${local.kube_path}/${local.config_filename}"
  talos_path         = "~/.talos"
  talos_config_path  = "${local.talos_path}/${local.config_filename}"
  dist_directory     = "${path.module}/dist"
  cilium_filepath    = "${local.dist_directory}/cilium.yaml"
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

resource "terraform_data" "cilium_yaml" {
  input = local.cilium_filepath

  lifecycle {
    replace_triggered_by = [talos_machine_secrets.this]
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
    mkdir -p ${local.dist_directory}
    echo "*" > ${local.dist_directory}/.gitignore
    helm template \
          cilium \
          cilium/cilium \
          --version 1.18.0 \
          --namespace kube-system \
          --set ipam.mode=kubernetes \
          --set kubeProxyReplacement=true \
          --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
          --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
          --set cgroup.autoMount.enabled=false \
          --set cgroup.hostRoot=/sys/fs/cgroup \
          --set k8sServiceHost=localhost \
          --set k8sServicePort=7445 > ${local.cilium_filepath}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
    rm -rf ${path.module}/dist
    EOT
  }
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = module.controlplane.hostnames
}

data "talos_machine_configuration" "cp" {
  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = local.cp
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "cp" {
  for_each = module.controlplane.hostnames

  depends_on = [
    module.controlplane,
    data.talos_client_configuration.this
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  node                        = each.value

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        inlineManifests = [
          {
            name     = "cilium"
            contents = file(terraform_data.cilium_yaml.output)
          }
        ]
      }
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.cp]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_plane_node
}

data "talos_machine_configuration" "worker" {
  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [file("${path.module}/data/longhorn.yaml")]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = module.worker.hostnames

  depends_on = [
    module.worker,
    data.talos_client_configuration.this,
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value

}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_plane_node
}


resource "null_resource" "write_kubeconfig" {
  depends_on = [talos_cluster_kubeconfig.this]

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${local.kube_path}
      echo '${talos_cluster_kubeconfig.this.kubeconfig_raw}' > ${local.kube_config_path}
      chmod 600 ${local.kube_config_path}
    EOT
  }
}

resource "null_resource" "write_talosconfig" {
  depends_on = [talos_cluster_kubeconfig.this]

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${local.talos_path}
      echo '${data.talos_client_configuration.this.talos_config}' > ${local.talos_config_path}
      chmod 600 ${local.talos_config_path}
    EOT
  }
}
