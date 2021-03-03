# Solar Winds Logs & Metrics

It's an add-on for Solar Winds Snap which will search for active services and will try to create a task to send metrics and serivice logs

# Installation

Required Solar Winds Snap. If not installed on the node group the install will fail.

# How do I use it

It's designed to create/remove Solar Winds Snap task in /opt/SolarWinds/Snap/etc/tasks-autoload.d/. It will also try to detect webserver logs and configure webserver status page.

# Works on

Nginx based nodes
