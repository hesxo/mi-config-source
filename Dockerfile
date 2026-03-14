FROM wso2/wso2mi:4.5.0

USER root
COPY src/synapse-config/api/ /home/wso2carbon/wso2mi-4.5.0/repository/deployment/server/synapse-configs/default/api/
RUN chown -R wso2carbon:wso2 /home/wso2carbon/wso2mi-4.5.0/repository/deployment/server/synapse-configs/default/
USER wso2carbon

EXPOSE 8290 8253 9164
