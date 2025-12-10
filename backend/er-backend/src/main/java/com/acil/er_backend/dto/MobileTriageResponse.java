package com.acil.er_backend.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class MobileTriageResponse {
    private Integer queueNumber;
    private Integer estimatedWaitMinutes;
    private Integer urgencyLevel;
    private String urgencyLabel;
    private String responseText;
    private String reasoning;
    private String status;
    private String patientName;
    private Integer waitingAhead;
    private String message;

    public Integer getQueueNumber() { return queueNumber; }
    public void setQueueNumber(Integer queueNumber) { this.queueNumber = queueNumber; }
    public Integer getEstimatedWaitMinutes() { return estimatedWaitMinutes; }
    public void setEstimatedWaitMinutes(Integer estimatedWaitMinutes) { this.estimatedWaitMinutes = estimatedWaitMinutes; }
    public Integer getUrgencyLevel() { return urgencyLevel; }
    public void setUrgencyLevel(Integer urgencyLevel) { this.urgencyLevel = urgencyLevel; }
    public String getUrgencyLabel() { return urgencyLabel; }
    public void setUrgencyLabel(String urgencyLabel) { this.urgencyLabel = urgencyLabel; }
    public String getResponseText() { return responseText; }
    public void setResponseText(String responseText) { this.responseText = responseText; }
    public String getReasoning() { return reasoning; }
    public void setReasoning(String reasoning) { this.reasoning = reasoning; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }
    public Integer getWaitingAhead() { return waitingAhead; }
    public void setWaitingAhead(Integer waitingAhead) { this.waitingAhead = waitingAhead; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}

