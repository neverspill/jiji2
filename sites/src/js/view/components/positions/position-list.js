import React                from "react"
import MUI                  from "material-ui"
import AbstractList         from "../widgets/abstract-list"
import PositionListItem     from "./position-list-item"


export default class PositionList extends AbstractList {

  constructor(props) {
    super(props);
    this.state = {};
  }

  get className() {
    return "position-list";
  }

  createListItem(position, index) {
    return <PositionListItem
      key={index}
      position={position}
      onTouchTap={this.createAction(position)}
      selected={
        this.state.selectedId === position.id
      } />;
  }
  createAction(position) {
    return (ev) => {
      this.context.router.transitionTo("/rmt/positions/"+position.id);
      ev.preventDefault();
    };
  }
}
PositionList.propTypes = {
  model: React.PropTypes.object.isRequired,
  selectionModel: React.PropTypes.object,
  emptyLabel:  React.PropTypes.string,
  autoFill: React.PropTypes.bool
};
PositionList.defaultProps = {
  selectionModel: null,
  emptyLabel: "建玉はありません",
  autoFill: false
};
PositionList.contextTypes = {
  router: React.PropTypes.func,
  windowResizeManager: React.PropTypes.object
};
