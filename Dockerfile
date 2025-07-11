FROM tomcat:latest 

# Fix the webapps directory (there was a typo in the original)
RUN cp -R /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

# Copy the WAR file to Tomcat webapps directory
COPY abc.war /usr/local/tomcat/webapps/ABCtechnologies-1.0.war

# Expose port 8080
EXPOSE 8080

# Start Tomcat server
CMD ["catalina.sh", "run"] 