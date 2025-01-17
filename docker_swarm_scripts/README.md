# Ne işe yarar?

Docker yedekliliğini sağlamak için, Docker Swarm'ın kurulumunu ve yapılandırmasını otomatik olarak yapar.

# Ne içerir?

- `swarm_initializer_funcitons.sh`: Docker swarm'ın sunucular arasında Worker ve Manager olarak yapılandırılmasını sağlayan fonksiyonları içerir.
- `swarm_initializer.sh`: Docker swarm'ın sunucular arasında Worker ve Manager olarak yapılandırılmasını sağlayan ana script dosyasıdır. Bu script dosyası çalıştırılmazsa diğer servis yedekliliği sağlanamaz.
- `set_swarm_node_variables.sh`: Docker Swarm'ın Worker-Manager kurulumu ve yapılandırmasının hangi sunucuda yapıldığına göre `CURRENT_NODE_IP` değerini atama işlemlerini yapar.