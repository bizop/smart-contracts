// SPDX-License-Identifier: MIT LICENSE
// A hypothetical test to see how many levels of turtles we can go down!

pragma solidity 0.8.7;

contract Nested {

    mapping(uint256 => Project) public projects;
    mapping(address => Assignee) public assignees;

    uint256 numProjects = 0;
    uint256 numAssignees = 0;

    struct Project {
        uint256 projectId;
        string projectName;
        uint256 numMilestones;
        mapping(uint256 => Milestone) milestones;
    }

    struct Milestone {
        uint256 projectId;
        uint256 milestoneId;
        string milestoneName;
        uint256 numTasks;
        mapping(uint256 => Task) tasks;
    }

    struct Task {
        uint256 projectId;
        uint256 milestoneId;
        uint256 taskId;
        string taskName;
        address assignee;
    }

    struct Assignee {
        string firstName;
        string lastName;
        uint256 numTasks;
    }

    function addProject(string memory _projectName) public {
        ++numProjects;
        uint256 _projectId = numProjects;
        Project storage p = projects[_projectId];
        p.projectId = _projectId;
        p.projectName = _projectName;
    }

    function addMilestone(uint256 _projectId, string memory _milestoneName) public {
        Project storage p = projects[_projectId];
        ++p.numMilestones;
        uint256 _milestoneId = projects[_projectId].numMilestones;
        Milestone storage m = projects[_projectId].milestones[_milestoneId];
        m.milestoneId = _milestoneId;
        m.milestoneName = _milestoneName;
    }

    function addTask(uint256 _projectId, uint256 _milestoneId, string memory _taskName, address _assignee) public {
        Milestone storage m = projects[_projectId].milestones[_milestoneId];
        ++m.numTasks;
        uint256 _taskId = projects[_projectId].milestones[_milestoneId].numTasks;
        Task storage t = projects[_projectId].milestones[_milestoneId].tasks[_taskId];
        t.taskId = _taskId;
        t.taskName = _taskName;
        t.assignee = _assignee;
        Assignee storage a = assignees[_assignee];
        ++a.numTasks;
    }

    function addAssignee(address _assigneeId, string memory _firstName, string memory _lastName) public {
        ++numAssignees;
        Assignee storage a = assignees[_assigneeId];
        a.firstName = _firstName;
        a.lastName = _lastName;
    }

    function getMilestone(uint256 _projectId, uint256 _milestoneId) public view returns (string memory milestoneName, uint256 numTasks) {
        string memory _milestoneName = projects[_projectId].milestones[_milestoneId].milestoneName;
        uint256 _numTasks = projects[_projectId].milestones[_milestoneId].numTasks;
        return (_milestoneName, _numTasks);
    }

    function getTask(uint256 _projectId, uint256 _milestoneId, uint256 _taskId) public view returns (string memory taskName, string memory assignee){
        string memory _taskName = projects[_projectId].milestones[_milestoneId].tasks[_taskId].taskName;
        address _assignee = projects[_projectId].milestones[_milestoneId].tasks[_taskId].assignee;
        string memory _assigneeName = string(abi.encodePacked(assignees[_assignee].firstName, " ", assignees[_assignee].lastName));
        return (_taskName, _assigneeName);
    }

}
